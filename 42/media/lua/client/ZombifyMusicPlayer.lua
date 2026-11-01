-- Zombify Music Player Integration
-- Connects to external WebSocket controller for Spotify/YouTube Music/Local
-- Falls back to demo mode when controller not available

ZombifyMusicPlayer = ZombifyMusicPlayer or {}

-- Music player connection state
ZombifyMusicPlayer.connections = {
    spotify = {connected = false, ws = nil, reconnectTimer = 0},
    youtubemusic = {connected = false, ws = nil, reconnectTimer = 0},
    local = {connected = false},
}

-- Current player info
ZombifyMusicPlayer.currentPlayer = nil
ZombifyMusicPlayer.demoMode = false
ZombifyMusicPlayer.lastUpdate = 0
ZombifyMusicPlayer.messageQueue = {}

-- Initialize music player connections
function ZombifyMusicPlayer.init()
    print("[ZombifyMusicPlayer] Initializing...")
    Events.OnTick.Add(ZombifyMusicPlayer.onTick)
end

-- Main tick handler
function ZombifyMusicPlayer.onTick()
    if not Zombify.Config or not Zombify.Config.enabled or Zombify.Config.modMode == "Disabled" then
        ZombifyMusicPlayer.disconnectAll()
        return
    end

    local currentTime = getTimestampMs()

    -- Handle reconnection logic
    ZombifyMusicPlayer.handleReconnect(currentTime)

    -- Process message queue
    ZombifyMusicPlayer.processQueue()

    -- Update music info periodically
    if currentTime - (ZombifyMusicPlayer.lastUpdate or 0) > 1000 then
        ZombifyMusicPlayer.update()
        ZombifyMusicPlayer.lastUpdate = currentTime
    end
end

-- Connect to a music player type
function ZombifyMusicPlayer.connect(playerType)
    ZombifyMusicPlayer.disconnectAll()
    ZombifyMusicPlayer.currentPlayer = playerType
    ZombifyMusicPlayer.demoMode = false

    if playerType == "spotify" then
        ZombifyMusicPlayer.connectWebSocket("spotify", Zombify.Config.controllerHost, ZombifyShared.Players[1].controllerPort)
    elseif playerType == "youtubemusic" then
        ZombifyMusicPlayer.connectWebSocket("youtubemusic", Zombify.Config.controllerHost, ZombifyShared.Players[2].controllerPort)
    elseif playerType == "local" then
        ZombifyMusicPlayer.connectLocal()
    end
end

-- Connect via WebSocket to external controller
function ZombifyMusicPlayer.connectWebSocket(playerType, host, port)
    local conn = ZombifyMusicPlayer.connections[playerType]
    if conn.connected then return end

    print("[ZombifyMusicPlayer] Attempting WebSocket connection to " .. playerType .. " on " .. host .. ":" .. port)

    -- Try to connect via WebSocket
    -- Note: PZ doesn't have built-in WebSocket support in Lua
    -- This would require a Java mod or external tool
    -- For now, we'll try to use a simple TCP socket approach
    local success = ZombifyMusicPlayer.trySocketConnection(playerType, host, port)

    if not success then
        print("[ZombifyMusicPlayer] WebSocket not available, enabling demo mode for " .. playerType)
        ZombifyMusicPlayer.enableDemoMode(playerType)
    end
end

-- Try socket connection (PZ Lua doesn't have native WebSocket, using demo mode)
function ZombifyMusicPlayer.trySocketConnection(playerType, host, port)
    -- PZ Lua environment doesn't have native WebSocket or TCP socket support
    -- This would require:
    -- 1. A Java mod that provides WebSocket API
    -- 2. An external controller app that communicates via file/pipe
    -- 3. Using the Steam API or similar

    -- For now, return false to enable demo mode
    return false
end

-- Enable demo mode for testing
function ZombifyMusicPlayer.enableDemoMode(playerType)
    ZombifyMusicPlayer.demoMode = true
    ZombifyMusicPlayer.connections[playerType].connected = true
    Zombify.State.playerConnected = true
    Zombify.State.playerType = playerType:gsub("^%l", string.upper)
    print("[ZombifyMusicPlayer] Demo mode enabled for " .. playerType)

    -- Initialize with first track
    if Zombify.State.currentTrack == nil then
        ZombifyMusicPlayer.simulateTrackChange()
    end
end

-- Connect to local music player (demo mode)
function ZombifyMusicPlayer.connectLocal()
    ZombifyMusicPlayer.enableDemoMode("local")
end

-- Handle reconnection logic
function ZombifyMusicPlayer.handleReconnect(currentTime)
    if ZombifyMusicPlayer.demoMode then return end

    for playerType, conn in pairs(ZombifyMusicPlayer.connections) do
        if not conn.connected and conn.reconnectTimer and currentTime > conn.reconnectTimer then
            conn.reconnectTimer = currentTime + 30000 -- Retry every 30 seconds
            if playerType == "spotify" then
                ZombifyMusicPlayer.connectWebSocket("spotify", Zombify.Config.controllerHost, ZombifyShared.Players[1].controllerPort)
            elseif playerType == "youtubemusic" then
                ZombifyMusicPlayer.connectWebSocket("youtubemusic", Zombify.Config.controllerHost, ZombifyShared.Players[2].controllerPort)
            end
        end
    end
end

-- Process incoming message queue
function ZombifyMusicPlayer.processQueue()
    while #ZombifyMusicPlayer.messageQueue > 0 do
        local msg = table.remove(ZombifyMusicPlayer.messageQueue, 1)
        ZombifyMusicPlayer.handleMessage(msg.playerType, msg.data)
    end
end

-- Update music info (called periodically)
function ZombifyMusicPlayer.update()
    if ZombifyMusicPlayer.demoMode then
        ZombifyMusicPlayer.updateDemo()
    else
        -- In real mode, would request update from controller
        ZombifyMusicPlayer.sendRawCommand("get_status", {})
    end
end

-- Update demo mode with simulated playback
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

-- Simulate track changes for demo purposes
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
    if ZombifyMusicPlayer.demoMode then
        ZombifyMusicPlayer.handleDemoCommand(command, params)
    else
        ZombifyMusicPlayer.sendRawCommand(command, params)
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

-- Send raw command to external controller (placeholder)
function ZombifyMusicPlayer.sendRawCommand(command, params)
    -- In real implementation, this would send JSON over WebSocket
    local msg = {
        command = command,
        params = params,
        timestamp = getTimestampMs()
    }
    print("[ZombifyMusicPlayer] Would send to controller: " .. command)
end

-- Handle incoming message from controller
function ZombifyMusicPlayer.handleMessage(playerType, data)
    if data.type == "status" then
        Zombify.State.currentTrack = data.track
        Zombify.State.currentArtist = data.artist
        Zombify.State.currentAlbum = data.album
        Zombify.State.duration = data.duration or 0
        Zombify.State.progress = data.progress or 0
        Zombify.State.isPlaying = data.isPlaying or false
        Zombify.State.volume = data.volume or 1.0
        Zombify.State.albumArt = data.albumArt
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
    end
end

-- Disconnect all players
function ZombifyMusicPlayer.disconnectAll()
    ZombifyMusicPlayer.connections.spotify.connected = false
    ZombifyMusicPlayer.connections.youtubemusic.connected = false
    ZombifyMusicPlayer.connections.local.connected = false
    Zombify.State.playerConnected = false
    Zombify.State.playerType = "None"
    ZombifyMusicPlayer.demoMode = false
    ZombifyMusicPlayer.currentPlayer = nil
    print("[ZombifyMusicPlayer] Disconnected from all players")
end

-- Queue message for processing
function ZombifyMusicPlayer.queueMessage(playerType, data)
    table.insert(ZombifyMusicPlayer.messageQueue, {playerType = playerType, data = data})
end

-- External API for controller to push updates
function ZombifyMusicPlayer.onControllerMessage(jsonString)
    -- Called from Java mod or external tool via Lua callback
    local ok, data = pcall(function() return parseJson(jsonString) end)
    if ok and data then
        ZombifyMusicPlayer.queueMessage(data.playerType, data)
    end
end

-- Initialize
Events.OnInitGlobalModData.Add(ZombifyMusicPlayer.init)