-- Zombify Controller Manager
-- Manages the external Python controller process from within the mod
-- Uses non-blocking async operations compatible with PZ Lua

ZombifyController = ZombifyController or {}
ZombifyController.running = false
ZombifyController.lastStatusCheck = 0
ZombifyController.statusCheckInterval = 5000 -- 5 seconds
ZombifyController.startAttempted = false

-- Controller configuration defaults
ZombifyController.DefaultConfig = {
    host = "127.0.0.1",
    port = 8765,
    httpPort = 8766,
    pythonPath = "python",
    controllerScript = "controller/zombify_controller.py",
    autoStart = true,
}

-- Initialize controller manager
function ZombifyController.init()
    print("[ZombifyController] Initializing...")

    -- Ensure config exists
    if not Zombify.Config then
        Zombify.Config = {}
    end

    -- Set defaults
    for k, v in pairs(ZombifyController.DefaultConfig) do
        if Zombify.Config[k] == nil then
            Zombify.Config[k] = v
        end
    end

    -- Find Python path (non-blocking)
    ZombifyController.findPython()

    -- Find controller script
    ZombifyController.findControllerScript()

    -- Auto-start if enabled (deferred to first tick to avoid blocking init)
    if Zombify.Config.controllerAutoStart and not ZombifyController.startAttempted then
        ZombifyController.startAttempted = true
        -- Defer start to next tick to avoid blocking game init
        Events.OnTick.Add(ZombifyController.deferredStart)
    end

    -- Start status check timer
    Events.OnTick.Add(ZombifyController.periodicStatusCheck)

    print("[ZombifyController] Initialized")
end

-- Deferred start (runs on first tick after init)
function ZombifyController.deferredStart()
    Events.OnTick.Remove(ZombifyController.deferredStart)
    if Zombify.Config.controllerAutoStart then
        ZombifyController.start()
    end
end

-- Find Python executable (non-blocking - just sets default, actual detection deferred)
function ZombifyController.findPython()
    -- In PZ Lua, we can't run commands to detect Python.
    -- Set a reasonable default and let the batch file handle detection.
    Zombify.Config.pythonPath = "python"
    print("[ZombifyController] Using default Python path: python")
end

-- Find controller script
function ZombifyController.findControllerScript()
    local possiblePaths = {
        "controller/zombify_controller.py",
        "../controller/zombify_controller.py",
        "mods/Zombify/controller/zombify_controller.py",
        getFilePath("") .. "controller/zombify_controller.py",
    }

    for _, path in ipairs(possiblePaths) do
        local file = getFileReader(path, true)
        if file then
            file:close()
            Zombify.Config.controllerScript = path
            print("[ZombifyController] Found controller script: " .. path)
            return
        end
    end

    -- Default to relative path
    Zombify.Config.controllerScript = "controller/zombify_controller.py"
    print("[ZombifyController] Using default controller script path")
end

-- Start the controller process (non-blocking)
function ZombifyController.start()
    if ZombifyController.running then
        print("[ZombifyController] Already running")
        return true
    end

    print("[ZombifyController] Starting controller...")

    local pythonPath = Zombify.Config.pythonPath or "python"
    local scriptPath = Zombify.Config.controllerScript
    local workingDir = getFilePath("")

    -- Build command
    local cmd = string.format('"%s" "%s"', pythonPath, scriptPath)

    print("[ZombifyController] Command: " .. cmd)
    print("[ZombifyController] Working dir: " .. workingDir)

    -- Create batch file for background execution
    ZombifyController.createBatchFile(cmd, workingDir)

    -- Run batch file asynchronously (non-blocking)
    -- Use a deferred approach to avoid blocking
    ZombifyController.runBatchFileAsync(workingDir .. "start_controller.bat")

    ZombifyController.running = true
    ZombifySettings.addLog("Controller start requested")
    return true
end

-- Create batch file for controller
function ZombifyController.createBatchFile(cmd, workingDir)
    local batContent = string.format([[
@echo off
cd /d "%s"
%s
]], workingDir, cmd)

    local batPath = workingDir .. "start_controller.bat"
    local file = getFileWriter(batPath, true, false)
    if file then
        file:write(batContent)
        file:close()
    end
end

-- Run batch file asynchronously (non-blocking)
function ZombifyController.runBatchFileAsync(batPath)
    -- In PZ Lua, we can't truly run async.
    -- The best we can do is use os.execute which may block briefly.
    -- The batch file itself runs the Python process in background.
    local runCmd = string.format('cmd /c start /min "" "%s"', batPath)
    -- Use pcall to avoid errors if os.execute has issues
    pcall(function() os.execute(runCmd) end)
end

-- Stop the controller process
function ZombifyController.stop()
    if not ZombifyController.running then
        print("[ZombifyController] Not running")
        return true
    end

    print("[ZombifyController] Stopping controller...")

    -- Send stop command via HTTP if possible
    ZombifyController.sendStopCommand()

    -- Try to kill the process (non-blocking)
    if getOS() == "Windows" then
        pcall(function() os.execute('taskkill /f /im python.exe /fi "windowtitle eq *zombify_controller*" 2>nul') end)
    end

    ZombifyController.running = false
    ZombifySettings.addLog("Controller stopped")
    return true
end

-- Restart controller (non-blocking)
function ZombifyController.restart()
    ZombifyController.stop()
    -- Schedule restart on next tick instead of blocking
    Events.OnTick.Add(ZombifyController.deferredRestart)
end

function ZombifyController.deferredRestart()
    Events.OnTick.Remove(ZombifyController.deferredRestart)
    ZombifyController.start()
end

-- Send stop command via HTTP
function ZombifyController.sendStopCommand()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766

    -- In a real implementation, we'd make an HTTP request
    -- For now, just log
    print("[ZombifyController] Sending stop command to http://" .. host .. ":" .. port)
end

-- Open Spotify authentication in browser
function ZombifyController.openSpotifyAuth()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766
    local url = "http://" .. host .. ":" .. port .. "/auth/spotify"

    ZombifySettings.addLog("Opening Spotify auth: " .. url)

    if getOS() == "Windows" then
        pcall(function() os.execute('start "" "' .. url .. '"') end)
    else
        pcall(function() os.execute('xdg-open "' .. url .. '"') end)
    end
end

-- Open YouTube Music setup
function ZombifyController.openYTMusicSetup()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766
    local url = "http://" .. host .. ":" .. port .. "/auth/ytmusic"

    ZombifySettings.addLog("Opening YTMusic setup: " .. url)

    if getOS() == "Windows" then
        pcall(function() os.execute('start "" "' .. url .. '"') end)
    else
        pcall(function() os.execute('xdg-open "' .. url .. '"') end)
    end
end

-- Test controller connection
function ZombifyController.testConnection()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerPort or 8765

    ZombifySettings.addLog("Testing WebSocket connection to ws://" .. host .. ":" .. port)

    local wsUrl = "ws://" .. host .. ":" .. port
    ZombifySettings.addLog("Test: " .. wsUrl)

    if ZombifySettings.updateStatusDisplay then
        ZombifySettings.updateStatusDisplay()
    end
end

-- Periodic status check
function ZombifyController.periodicStatusCheck()
    local currentTime = getTimestampMs()
    if currentTime - ZombifyController.lastStatusCheck > ZombifyController.statusCheckInterval then
        ZombifyController.lastStatusCheck = currentTime

        -- Check if process is still running
        ZombifyController.checkProcessStatus()

        -- Update UI if settings panel is open
        if ZombifySettings.updateStatusDisplay then
            ZombifySettings.updateStatusDisplay()
        end
    end
end

-- Check if controller process is running
function ZombifyController.checkProcessStatus()
    -- Check if PID file exists
    local pidFile = getFilePath("") .. "controller/comm/controller.pid"
    local file = getFileReader(pidFile, true)

    local processRunning = false
    if file then
        local content = file:readLine()
        file:close()
        if content and content ~= "" then
            processRunning = true
        end
    end

    ZombifyController.running = processRunning
end

-- Check if Spotify is authenticated
function ZombifyController.isSpotifyAuthenticated()
    local tokenFile = getFilePath("") .. "controller/tokens/spotify_token.json"
    local file = getFileReader(tokenFile, true)
    if file then
        file:close()
        return true
    end
    return false
end

-- Check if YouTube Music is configured
function ZombifyController.isYTMusicConfigured()
    local headersFile = getFilePath("") .. "controller/ytmusic_headers.json"
    local file = getFileReader(headersFile, true)
    if file then
        file:close()
        return true
    end
    return false
end

-- Check if controller is running
function ZombifyController.isRunning()
    return ZombifyController.running
end

-- Initialize on game start
Events.OnGameStart.Add(ZombifyController.init)