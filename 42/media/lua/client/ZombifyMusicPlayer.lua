-- Zombify Music Player Integration
-- Communicates with external Python controller via file-based IPC
-- Falls back to demo mode when controller not available

ZombifyMusicPlayer = ZombifyMusicPlayer or {}

-- Communication file paths
ZombifyMusicPlayer.COMM_DIR = "controller/comm/"
ZombifyMusicPlayer.STATUS_FILE = "controller/comm/status.json"
ZombifyMusicPlayer.COMMAND_FILE = "controller/comm/command.json"
ZombifyMusicPlayer.CONTROLLER_PID_FILE = "controller/comm/controller.pid"

-- Music player connection state
ZombifyMusicPlayer.connections = {
    spotify = {connected = false, lastUpdate = 0},
    youtubemusic = {connected = false, lastUpdate = 0},
    local = {connected = false, lastUpdate = 0},
}

-- Current player info
ZombifyMusicPlayer.currentPlayer = nil
ZombifyMusicPlayer.demoMode = false
ZombifyMusicPlayer.lastStatusCheck = 0
ZombifyMusicPlayer.statusCheckInterval = 1000 -- 1 second
ZombifyMusicPlayer.lastCommandId = 0
ZombifyMusicPlayer.connectionStartTime = 0
ZombifyMusicPlayer.connecting = false

-- Initialize music player
function ZombifyMusicPlayer.init()
    print("[ZombifyMusicPlayer] Initializing file-based IPC...")

    -- Ensure communication directory exists
    ZombifyMusicPlayer.ensureCommDir()

    -- Clean up old files
    ZombifyMusicPlayer.cleanupCommFiles()

    Events.OnTick.Add(ZombifyMusicPlayer.onTick)
    print("[ZombifyMusicPlayer] Initialized")
end

-- Ensure communication directory exists
function ZombifyMusicPlayer.ensureCommDir()
    local commDir = getFilePath("") .. ZombifyMusicPlayer.COMM_DIR
    -- Directory creation happens when we write files
end

-- Clean up old communication files
function ZombifyMusicPlayer.cleanupCommFiles()
    local files = {
        ZombifyMusicPlayer.STATUS_FILE,
        ZombifyMusicPlayer.COMMAND_FILE,
        ZombifyMusicPlayer.CONTROLLER_PID_FILE,
    }
    for _, file in ipairs(files) do
        local path = getFilePath("") .. file
        -- File deletion would happen here if we had file delete API
    end
end

-- Main tick handler
function ZombifyMusicPlayer.onTick()
    if not Zombify.Config or not Zombify.Config.enabled or Zombify.Config.modMode == "Disabled" then
        ZombifyMusicPlayer.disconnectAll()
        return
    end

    local currentTime = getTimestampMs()

    -- Check controller status and read updates
    if currentTime - ZombifyMusicPlayer.lastStatusCheck > ZombifyMusicPlayer.statusCheckInterval then
        ZombifyMusicPlayer.lastStatusCheck = currentTime
        ZombifyMusicPlayer.checkControllerStatus()
        ZombifyMusicPlayer.readStatusFile()
    end

    -- Handle async connection
    if ZombifyMusicPlayer.connecting then
        ZombifyMusicPlayer.checkConnectionAsync()
    end

    -- Process pending commands
    ZombifyMusicPlayer.processCommandQueue()

    -- Update demo mode playback
    if ZombifyMusicPlayer.demoMode and Zombify.State.isPlaying then
        ZombifyMusicPlayer.updateDemo()
    end
end

-- Check if controller is running
function ZombifyMusicPlayer.checkControllerStatus()
    local pidFile = getFilePath("") .. ZombifyMusicPlayer.CONTROLLER_PID_FILE
    local file = getFileReader(pidFile, true)

    local controllerRunning = false
    if file then
        local content = file:readLine()
        file:close()
        if content and content ~= "" then
            local pid = tonumber(content)
            if pid then
                controllerRunning = ZombifyMusicPlayer.isProcessRunning(pid)
            end
        end
    end

    -- Update connection state based on controller status
    if controllerRunning and not ZombifyMusicPlayer.demoMode then
        -- Controller is running, try to read status
        ZombifyMusicPlayer.connections[ZombifyMusicPlayer.currentPlayer or "spotify"].connected = true
        Zombify.State.playerConnected = true
    elseif not controllerRunning then
        -- Controller not running, fall back to demo mode
        if not ZombifyMusicPlayer.demoMode then
            print("[ZombifyMusicPlayer] Controller not running, enabling demo mode")
            ZombifyMusicPlayer.enableDemoMode(ZombifyMusicPlayer.currentPlayer or "spotify")
        end
    end
end

-- Check if process is running (Windows) - simplified, no io.popen
function ZombifyMusicPlayer.isProcessRunning(pid)
    -- In PZ Lua, we can't use io.popen.
    -- For now, assume process is running if PID file exists with valid content.
    -- The controller manages its own lifecycle.
    return pid and pid > 0
end

-- Read status file from controller
function ZombifyMusicPlayer.readStatusFile()
    local statusFile = getFilePath("") .. ZombifyMusicPlayer.STATUS_FILE
    local file = getFileReader(statusFile, true)

    if not file then
        return
    end

    local content = file:readLine()
    file:close()

    if not content or content == "" then
        return
    end

    -- Parse JSON status
    local ok, status = pcall(function() return parseJson(content) end)
    if not ok or not status then
        return
    end

    -- Update state from controller
    ZombifyMusicPlayer.handleMessage("controller", status)
end

-- Connect to a music player type (async, non-blocking)
function ZombifyMusicPlayer.connect(playerType)
    ZombifyMusicPlayer.disconnectAll()
    ZombifyMusicPlayer.currentPlayer = playerType
    ZombifyMusicPlayer.demoMode = false
    ZombifyMusicPlayer.connecting = true
    ZombifyMusicPlayer.connectionStartTime = getTimestampMs()

    print("[ZombifyMusicPlayer] Connecting to " .. playerType .. " via controller...")

    -- Send connect command to controller
    ZombifyMusicPlayer.sendCommand("connect", {playerType = playerType})
end

-- Async connection check (called from onTick)
function ZombifyMusicPlayer.checkConnectionAsync()
    if not ZombifyMusicPlayer.connecting then return end

    local currentTime = getTimestampMs()
    local elapsed = currentTime - ZombifyMusicPlayer.connectionStartTime

    -- Check for status update
    ZombifyMusicPlayer.readStatusFile()

    if Zombify.State.playerConnected then
        ZombifyMusicPlayer.connecting = false
        print("[ZombifyMusicPlayer] Connected successfully")
        return
    end

    -- Timeout after 5 seconds
    if elapsed > 5000 then
        ZombifyMusicPlayer.connecting = false
        print("[ZombifyMusicPlayer] Controller connection timeout, enabling demo mode")
        ZombifyMusicPlayer.enableDemoMode(ZombifyMusicPlayer.currentPlayer or "spotify")
    end
end

-- Enable demo mode
function ZombifyMusicPlayer.enableDemoMode(playerType)
    ZombifyMusicPlayer.demoMode = true
    ZombifyMusicPlayer.currentPlayer = playerType
    Zombify.State.playerConnected = true
    Zombify.State.playerType = playerType:gsub("^%l", string.upper)
    print("[ZombifyMusicPlayer] Demo mode enabled for " .. playerType)

    if Zombify.State.currentTrack == nil then
        ZombifyMusicPlayer.simulateTrackChange()
    end
end

-- Connect to local (always demo)
function ZombifyMusicPlayer.connectLocal()
    ZombifyMusicPlayer.enableDemoMode("local")
end

-- Send command to controller via file
function ZombifyMusicPlayer.sendCommand(command, params)
    ZombifyMusicPlayer.lastCommandId = ZombifyMusicPlayer.lastCommandId + 1

    local cmd = {
        id = ZombifyMusicPlayer.lastCommandId,
        command = command,
        params = params or {},
        timestamp = getTimestampMs()
    }

    local ok, json = pcall(function() return toJson(cmd) end)
    if not ok then
        print("[ZombifyMusicPlayer] Failed to encode command")
        return
    end

    local commandFile = getFilePath("") .. ZombifyMusicPlayer.COMMAND_FILE
    local file = getFileWriter(commandFile, true, false)
    if file then
        file:write(json)
        file:close()
    end

    -- Also handle locally for demo mode
    if ZombifyMusicPlayer.demoMode then
        ZombifyMusicPlayer.handleDemoCommand(command, params)
    end
end

-- Process command queue (for responses from controller)
function ZombifyMusicPlayer.processCommandQueue()
    -- In a full implementation, we'd read response files here
    -- For now, commands are fire-and-forget
end

-- Main update - read status from controller
function ZombifyMusicPlayer.update()
    ZombifyMusicPlayer.readStatusFile()
end

-- Update demo mode playback
function ZombifyMusicPlayer.updateDemo()
    if not Zombify.State.isPlaying then return end

    local currentTime = getTimestampMs()
    if not Zombify.State.lastDemoUpdate then
        Zombify.State.lastDemoUpdate = currentTime
        return
    end

    local delta = currentTime - Zombify.State.lastDemoUpdate
    Zombify.State.progress = math.min(Zombify.State.progress + delta, Zombify.State.duration)

    if Zombify.State.progress >= Zombify.State.duration then
        ZombifyMusicPlayer.simulateTrackChange()
    end

    Zombify.State.lastDemoUpdate = currentTime
end

-- Simulate track changes for demo
function ZombifyMusicPlayer.simulateTrackChange()
    local tracks = {
        {title = "Survivor's Song", artist = "The Zombies", album = "Apocalypse Soundtrack", duration = 240000, art = nil},
        {title = "Last Stand", artist = "Wasteland Warriors", album = "End Times", duration = 195000, art = nil},
        {title = "Hope Remains", artist = "Dawn Chorus", album = "New Beginnings", duration = 210000, art = nil},
        {title = "Night Watch", artist = "Midnight Patrol", album = "Dark Hours", duration = 275000, art = nil},
        {title = "Supply Run", artist = "Scavenger Beats", album = "Loot & Scoot", duration = 180000, art = nil},
        {title = "Safe Zone", artist = "Haven Sounds", album = "Sanctuary", duration = 220000, art = nil},
        {title = "Horizon", artist = "Far Wanderers", album = "Beyond", duration = 260000, art = nil},
    }

    local track = tracks[math.random(1, #tracks)]
    Zombify.State.currentTrack = track.title
    Zombify.State.currentArtist = track.artist
    Zombify.State.currentAlbum = track.album
    Zombify.State.duration = track.duration
    Zombify.State.progress = 0
    Zombify.State.isPlaying = true
    Zombify.State.albumArt = track.art
    Zombify.State.lastDemoUpdate = getTimestampMs()
end

-- Send playback control command
function ZombifyMusicPlayer.sendCommand(command, params)
    -- Send to controller via file
    local cmd = {
        command = command,
        params = params or {}
    }
    ZombifyMusicPlayer.sendCommand(cmd.command, cmd.params)

    -- Handle locally for demo mode
    if ZombifyMusicPlayer.demoMode then
        ZombifyMusicPlayer.handleDemoCommand(command, params)
    end
end

-- Handle commands in demo mode
function ZombifyMusicPlayer.handleDemoCommand(command, params)
    if command == "play_pause" then
        Zombify.State.isPlaying = not Zombify.State.isPlaying
        print("[ZombifyMusicPlayer] Demo: " .. (Zombify.State.isPlaying and "Playing" or "Paused"))
    elseif command == "next" then
        ZombifyMusicPlayer.simulateTrackChange()
        print("[ZombifyMusicPlayer] Demo: Next track - " .. Zombify.State.currentTrack)
    elseif command == "previous" then
        ZombifyMusicPlayer.simulateTrackChange()
        print("[ZombifyMusicPlayer] Demo: Previous track - " .. Zombify.State.currentTrack)
    elseif command == "volume" then
        if params.volume then
            Zombify.State.volume = math.max(0, math.min(1, params.volume))
        elseif params.delta then
            Zombify.State.volume = math.max(0, math.min(1, (Zombify.State.volume or 0.5) + params.delta))
        end
        print("[ZombifyMusicPlayer] Demo: Volume " .. math.floor((Zombify.State.volume or 0.5) * 100) .. "%")
    end
end

-- Handle incoming message from controller
function ZombifyMusicPlayer.handleMessage(source, data)
    if data.type == "status" then
        Zombify.State.currentTrack = data.track
        Zombify.State.currentArtist = data.artist
        Zombify.State.currentAlbum = data.album
        Zombify.State.duration = data.duration or 0
        Zombify.State.progress = data.progress or 0
        Zombify.State.isPlaying = data.isPlaying or false
        Zombify.State.volume = data.volume or 1.0
        Zombify.State.albumArt = data.albumArt
        Zombify.State.playerConnected = true
    elseif data.type == "track_change" then
        Zombify.State.currentTrack = data.track
        Zombify.State.currentArtist = data.artist
        Zombify.State.currentAlbum = data.album
        Zombify.State.duration = data.duration or 0
        Zombify.State.progress = 0
        Zombify.State.isPlaying = true
        Zombify.State.albumArt = data.albumArt
    elseif data.type == "playback_state" then
        Zombify.State.isPlaying = data.isPlaying
        Zombify.State.progress = data.progress or Zombify.State.progress
    elseif data.type == "volume" then
        Zombify.State.volume = data.volume
    elseif data.type == "connected" then
        Zombify.State.playerConnected = true
        Zombify.State.playerType = data.playerType or "Unknown"
    elseif data.type == "disconnected" then
        Zombify.State.playerConnected = false
        if not ZombifyMusicPlayer.demoMode then
            ZombifyMusicPlayer.enableDemoMode(ZombifyMusicPlayer.currentPlayer or "spotify")
        end
    end
end

-- Disconnect all
function ZombifyMusicPlayer.disconnectAll()
    Zombify.State.playerConnected = false
    Zombify.State.playerType = "None"
    ZombifyMusicPlayer.demoMode = false
    ZombifyMusicPlayer.currentPlayer = nil
    ZombifyMusicPlayer.connecting = false
    print("[ZombifyMusicPlayer] Disconnected from all players")
end

-- External API for controller to push updates
function ZombifyMusicPlayer.onControllerMessage(jsonString)
    local ok, data = pcall(function() return parseJson(jsonString) end)
    if ok and data then
        ZombifyMusicPlayer.handleMessage("controller", data)
    end
end

-- Initialize
Events.OnInitGlobalModData.Add(ZombifyMusicPlayer.init)