-- Zombify Music Player Integration
-- Simplified demo mode - works without external controller

ZombifyMusicPlayer = ZombifyMusicPlayer or {}

-- Current player info
ZombifyMusicPlayer.currentPlayer = "spotify"
ZombifyMusicPlayer.demoMode = true
ZombifyMusicPlayer.lastUpdate = 0

-- Initialize music player
function ZombifyMusicPlayer.init()
    print("[ZombifyMusicPlayer] Initializing demo mode...")
    ZombifyMusicPlayer.demoMode = true
    ZombifyMusicPlayer.currentPlayer = "spotify"
    Zombify.State.playerConnected = true
    Zombify.State.playerType = "Spotify"
    print("[ZombifyMusicPlayer] Demo mode initialized")
end

-- Main tick handler - simplified, no file I/O
function ZombifyMusicPlayer.onTick()
    if not Zombify.Config or not Zombify.Config.enabled or Zombify.Config.modMode == "Disabled" then
        return
    end

    local currentTime = getTimeInMillis()

    -- Update demo mode playback
    if ZombifyMusicPlayer.demoMode and Zombify.State.isPlaying then
        ZombifyMusicPlayer.updateDemo()
    end

    -- Periodic status check (every 5 seconds)
    if currentTime - ZombifyMusicPlayer.lastUpdate > 5000 then
        ZombifyMusicPlayer.lastUpdate = currentTime
        -- In demo mode, just ensure we have a track
        if ZombifyMusicPlayer.demoMode and not Zombify.State.currentTrack then
            ZombifyMusicPlayer.simulateTrackChange()
        end
    end
end

-- Connect to a music player type - always demo mode for now
function ZombifyMusicPlayer.connect(playerType)
    ZombifyMusicPlayer.disconnectAll()
    ZombifyMusicPlayer.currentPlayer = playerType or "spotify"
    ZombifyMusicPlayer.demoMode = true
    Zombify.State.playerConnected = true
    Zombify.State.playerType = (playerType or "spotify"):gsub("^%l", string.upper)
    print("[ZombifyMusicPlayer] Demo mode enabled for " .. Zombify.State.playerType)

    if not Zombify.State.currentTrack then
        ZombifyMusicPlayer.simulateTrackChange()
    end
end

-- Enable demo mode
function ZombifyMusicPlayer.enableDemoMode(playerType)
    ZombifyMusicPlayer.demoMode = true
    ZombifyMusicPlayer.currentPlayer = playerType or "spotify"
    Zombify.State.playerConnected = true
    Zombify.State.playerType = (playerType or "spotify"):gsub("^%l", string.upper)
    print("[ZombifyMusicPlayer] Demo mode enabled for " .. Zombify.State.playerType)

    if not Zombify.State.currentTrack then
        ZombifyMusicPlayer.simulateTrackChange()
    end
end

-- Connect to local (always demo)
function ZombifyMusicPlayer.connectLocal()
    ZombifyMusicPlayer.enableDemoMode("local")
end

-- Main update
function ZombifyMusicPlayer.update()
    -- In demo mode, just ensure we have a track
    if ZombifyMusicPlayer.demoMode and not Zombify.State.currentTrack then
        ZombifyMusicPlayer.simulateTrackChange()
    end
end

-- Update demo mode playback
function ZombifyMusicPlayer.updateDemo()
    if not Zombify.State.isPlaying then return end

    local currentTime = getTimeInMillis()
    if not Zombify.State.lastDemoUpdate then
        Zombify.State.lastDemoUpdate = currentTime
        return
    end

    local delta = currentTime - Zombify.State.lastDemoUpdate
    Zombify.State.progress = math.min((Zombify.State.progress or 0) + delta, Zombify.State.duration or 0)

    if Zombify.State.progress >= (Zombify.State.duration or 0) then
        ZombifyMusicPlayer.simulateTrackChange()
    end

    Zombify.State.lastDemoUpdate = currentTime
end

-- Simulate track changes for demo
function ZombifyMusicPlayer.simulateTrackChange()
    local tracks = {
        {title = "Survivor's Song", artist = "The Zombies", album = "Apocalypse Soundtrack", duration = 240000},
        {title = "Last Stand", artist = "Wasteland Warriors", album = "End Times", duration = 195000},
        {title = "Hope Remains", artist = "Dawn Chorus", album = "New Beginnings", duration = 210000},
        {title = "Night Watch", artist = "Midnight Patrol", album = "Dark Hours", duration = 275000},
        {title = "Supply Run", artist = "Scavenger Beats", album = "Loot & Scoot", duration = 180000},
        {title = "Safe Zone", artist = "Haven Sounds", album = "Sanctuary", duration = 220000},
        {title = "Horizon", artist = "Far Wanderers", album = "Beyond", duration = 260000},
    }

    local track = tracks[ZombifyMath.random(1, #tracks)]
    Zombify.State.currentTrack = track.title
    Zombify.State.currentArtist = track.artist
    Zombify.State.currentAlbum = track.album
    Zombify.State.duration = track.duration
    Zombify.State.progress = 0
    Zombify.State.isPlaying = true
    Zombify.State.lastDemoUpdate = getTimeInMillis()
end

-- Send playback control command
function ZombifyMusicPlayer.sendCommand(command, params)
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
        print("[ZombifyMusicPlayer] Demo: Next track - " .. (Zombify.State.currentTrack or "none"))
    elseif command == "previous" then
        ZombifyMusicPlayer.simulateTrackChange()
        print("[ZombifyMusicPlayer] Demo: Previous track - " .. (Zombify.State.currentTrack or "none"))
    elseif command == "volume" then
        if params and params.volume then
            Zombify.State.volume = math.max(0, math.min(1, params.volume))
        elseif params and params.delta then
            Zombify.State.volume = math.max(0, math.min(1, (Zombify.State.volume or 0.5) + params.delta))
        end
        print("[ZombifyMusicPlayer] Demo: Volume " .. math.floor((Zombify.State.volume or 0.5) * 100) .. "%")
    end
end

-- Disconnect all
function ZombifyMusicPlayer.disconnectAll()
    Zombify.State.playerConnected = false
    Zombify.State.playerType = "None"
    ZombifyMusicPlayer.demoMode = false
    ZombifyMusicPlayer.currentPlayer = nil
    print("[ZombifyMusicPlayer] Disconnected from all players")
end

-- Initialize
Events.OnInitGlobalModData.Add(ZombifyMusicPlayer.init)