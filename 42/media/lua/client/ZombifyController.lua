-- Zombify Controller Manager
-- Manages the external Python controller process from within the mod

ZombifyController = ZombifyController or {}
ZombifyController.process = nil
ZombifyController.running = false
ZombifyController.lastStatusCheck = 0
ZombifyController.statusCheckInterval = 5000 -- 5 seconds

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

    -- Find Python path
    ZombifyController.findPython()

    -- Find controller script
    ZombifyController.findControllerScript()

    -- Auto-start if enabled
    if Zombify.Config.controllerAutoStart then
        ZombifyController.start()
    end

    -- Start status check timer
    Events.OnTick.Add(ZombifyController.periodicStatusCheck)

    print("[ZombifyController] Initialized")
end

-- Find Python executable
function ZombifyController.findPython()
    local pythonPaths = {
        "python",
        "python3",
        "python.exe",
        "py",
        "C:\\Python311\\python.exe",
        "C:\\Python310\\python.exe",
        "C:\\Python39\\python.exe",
        "C:\\Users\\" .. os.getenv("USERNAME") .. "\\AppData\\Local\\Programs\\Python\\Python311\\python.exe",
        "C:\\Users\\" .. os.getenv("USERNAME") .. "\\AppData\\Local\\Programs\\Python\\Python310\\python.exe",
    }

    for _, path in ipairs(pythonPaths) do
        -- Test if python exists by trying to run version
        local result = ZombifyController.runCommand(path .. " --version")
        if result and result:match("Python") then
            Zombify.Config.pythonPath = path
            print("[ZombifyController] Found Python: " .. path)
            return
        end
    end

    print("[ZombifyController] Warning: Python not found in standard locations")
    Zombify.Config.pythonPath = "python"
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

-- Start the controller process
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

    -- Start process using Lua's os.execute with background
    -- Note: PZ Lua doesn't have direct process management
    -- We'll use a workaround with os.execute and a batch file on Windows

    local success = ZombifyController.startProcess(cmd, workingDir)

    if success then
        ZombifyController.running = true
        ZombifySettings.addLog("Controller started successfully")
        return true
    else
        ZombifySettings.addLog("Failed to start controller")
        return false
    end
end

-- Start process (Windows batch file approach)
function ZombifyController.startProcess(cmd, workingDir)
    -- Create a batch file to run the controller in background
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

    -- Run batch file minimized
    local runCmd = string.format('cmd /c start /min "" "%s"', batPath)
    local result = os.execute(runCmd)

    return result == 0
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

    -- Also try to kill the process
    if getOS() == "Windows" then
        os.execute('taskkill /f /im python.exe /fi "windowtitle eq *zombify_controller*" 2>nul')
    end

    ZombifyController.running = false
    ZombifySettings.addLog("Controller stopped")
    return true
end

-- Restart controller
function ZombifyController.restart()
    ZombifyController.stop()
    -- Small delay then start
    local startTime = getTimestampMs()
    while getTimestampMs() - startTime < 1000 do
        -- Wait 1 second
    end
    return ZombifyController.start()
end

-- Send stop command via HTTP
function ZombifyController.sendStopCommand()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766

    -- We'll use a simple socket approach if available
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
        os.execute('start "" "' .. url .. '"')
    else
        os.execute('xdg-open "' .. url .. '"')
    end
end

-- Open YouTube Music setup
function ZombifyController.openYTMusicSetup()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766
    local url = "http://" .. host .. ":" .. port .. "/auth/ytmusic"

    ZombifySettings.addLog("Opening YTMusic setup: " .. url)

    if getOS() == "Windows" then
        os.execute('start "" "' .. url .. '"')
    else
        os.execute('xdg-open "' .. url .. '"')
    end
end

-- Test controller connection
function ZombifyController.testConnection()
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerPort or 8765

    ZombifySettings.addLog("Testing WebSocket connection to ws://" .. host .. ":" .. port)

    -- Try to connect via socket
    -- This is a simplified test - in reality we'd use a proper WebSocket client
    local wsUrl = "ws://" .. host .. ":" .. port
    ZombifySettings.addLog("Test: " .. wsUrl)

    -- Update status labels
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
    -- Try HTTP status endpoint
    local host = Zombify.Config.controllerHost or "127.0.0.1"
    local port = Zombify.Config.controllerHttpPort or 8766

    -- In a real implementation, we'd make an HTTP request
    -- For now, we'll use a simple approach
    ZombifyController.running = ZombifyController.isProcessRunning()
end

-- Check if process is running (simplified)
function ZombifyController.isProcessRunning()
    -- This is a placeholder - in reality we'd check the actual process
    -- For now, return the running state
    return ZombifyController.running
end

-- Check if Spotify is authenticated
function ZombifyController.isSpotifyAuthenticated()
    -- Check if Spotify token file exists
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

-- Run command and capture output
function ZombifyController.runCommand(cmd)
    -- This is a simplified version - PZ Lua doesn't have popen
    -- We'll return nil to indicate we can't capture output
    return nil
end

-- Get file path helper
function getFilePath(relative)
    -- Return the mod directory path
    return getDir("") -- This returns the current working directory
end

-- Initialize on game start
Events.OnGameStart.Add(ZombifyController.init)