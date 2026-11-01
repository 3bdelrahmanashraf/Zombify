-- Zombify Mod Initialization
-- Main entry point for the Zombify mod

-- Load shared module first
require "ZombifyShared"

-- Load client modules
if isClient() then
    require "ZombifyMain"
    require "ZombifyUI"
    require "ZombifySettings"
    require "ZombifyMusicPlayer"
    require "ZombifyController"
end

-- Mod metadata
Zombify = Zombify or {}
Zombify.name = "Zombify"
Zombify.version = "1.0.0"
Zombify.author = "3bdelrahmanashraf"
Zombify.description = "Music player integration for Project Zomboid - Display and control Spotify, YouTube Music, and other players in-game with track info, album art, and playback controls."
Zombify.url = "https://github.com/3bdelrahmanashraf/Zombify"

-- Log mod load
print("[Zombify] Loading Zombify v" .. Zombify.version .. " by " .. Zombify.author)
print("[Zombify] " .. Zombify.description)
print("[Zombify] GitHub: " .. Zombify.url)

-- Register console commands
if isClient() then
    local function zombifyCommand(player, args)
        if args and args[1] then
            local cmd = args[1]:lower()
            if cmd == "toggle" then
                ZombifyUI.toggle()
            elseif cmd == "show" then
                ZombifyUI.show()
            elseif cmd == "hide" then
                ZombifyUI.hide()
            elseif cmd == "settings" then
                ZombifySettings.open()
            elseif cmd == "next" then
                Zombify.controlNext()
            elseif cmd == "prev" or cmd == "previous" then
                Zombify.controlPrev()
            elseif cmd == "play" or cmd == "pause" then
                Zombify.controlPlayPause()
            elseif cmd == "vol" or cmd == "volume" then
                if args[2] then
                    local vol = tonumber(args[2])
                    if vol then
                        Zombify.State.volume = math.max(0, math.min(1, vol / 100))
                        ZombifyMusicPlayer.sendCommand("volume", {volume = Zombify.State.volume})
                        print("[Zombify] Volume set to " .. math.floor(Zombify.State.volume * 100) .. "%")
                    end
                else
                    print("[Zombify] Current volume: " .. math.floor((Zombify.State.volume or 0.5) * 100) .. "%")
                end
            elseif cmd == "connect" then
                if args[2] then
                    local mode = args[2]:lower()
                    if mode == "spotify" or mode == "youtubemusic" or mode == "local" then
                        Zombify.Config.modMode = mode:sub(1,1):upper() .. mode:sub(2)
                        if mode == "youtubemusic" then Zombify.Config.modMode = "YouTubeMusic" end
                        Zombify.saveConfig()
                        Zombify.initMusicPlayer()
                        print("[Zombify] Connecting to " .. mode .. "...")
                    else
                        print("[Zombify] Usage: /zombify connect <spotify|youtubemusic|local>")
                    end
                else
                    print("[Zombify] Usage: /zombify connect <spotify|youtubemusic|local>")
                end
            elseif cmd == "disconnect" then
                ZombifyMusicPlayer.disconnectAll()
                print("[Zombify] Disconnected from music player")
            elseif cmd == "status" then
                print("[Zombify] Status:")
                print("  Enabled: " .. tostring(Zombify.Config.enabled))
                print("  Mode: " .. (Zombify.Config.modMode or "Disabled"))
                print("  Connected: " .. tostring(Zombify.State.playerConnected))
                print("  Player: " .. (Zombify.State.playerType or "None"))
                print("  Playing: " .. tostring(Zombify.State.isPlaying))
                print("  Track: " .. (Zombify.State.currentTrack or "None"))
                print("  Artist: " .. (Zombify.State.currentArtist or "None"))
                print("  Volume: " .. math.floor((Zombify.State.volume or 0.5) * 100) .. "%")
                print("  Demo Mode: " .. tostring(ZombifyMusicPlayer.demoMode))
                print("  Controller: " .. (ZombifyController.isRunning() and "Running" or "Stopped"))
            elseif cmd == "demo" then
                if args[2] then
                    ZombifyMusicPlayer.enableDemoMode(args[2])
                else
                    ZombifyMusicPlayer.enableDemoMode("spotify")
                end
            elseif cmd == "controller" then
                if args[2] then
                    local subcmd = args[2]:lower()
                    if subcmd == "start" then
                        ZombifyController.start()
                    elseif subcmd == "stop" then
                        ZombifyController.stop()
                    elseif subcmd == "restart" then
                        ZombifyController.restart()
                    elseif subcmd == "spotify" then
                        ZombifyController.openSpotifyAuth()
                    elseif subcmd == "ytmusic" then
                        ZombifyController.openYTMusicSetup()
                    elseif subcmd == "test" then
                        ZombifyController.testConnection()
                    else
                        print("[Zombify] Controller commands: start, stop, restart, spotify, ytmusic, test")
                    end
                else
                    print("[Zombify] Controller commands: start, stop, restart, spotify, ytmusic, test")
                end
            elseif cmd == "help" then
                print("[Zombify] Commands:")
                print("  /zombify toggle - Toggle overlay visibility")
                print("  /zombify show - Show overlay")
                print("  /zombify hide - Hide overlay")
                print("  /zombify settings - Open settings panel")
                print("  /zombify next - Next track")
                print("  /zombify prev - Previous track")
                print("  /zombify play - Play/pause")
                print("  /zombify vol [0-100] - Get/set volume")
                print("  /zombify connect <player> - Connect to music player (spotify|youtubemusic|local)")
                print("  /zombify disconnect - Disconnect from music player")
                print("  /zombify status - Show current status")
                print("  /zombify demo [player] - Enable demo mode")
                print("  /zombify controller <cmd> - Controller management (start|stop|restart|spotify|ytmusic|test)")
                print("  /zombify help - Show this help")
            else
                print("[Zombify] Unknown command: " .. cmd)
                print("[Zombify] Type /zombify help for available commands")
            end
        else
            ZombifyUI.toggle()
        end
    end

    -- Register console command using the proper PZ API
    -- Commands are registered via the game's console system
    -- This creates a /zombify command
    local function registerCommands()
        -- PZ console commands are added via the Commands table
        -- This is the standard way in PZ Lua
        Commands = Commands or {}
        Commands.zombify = zombifyCommand
    end

    -- Register on game start to ensure Commands table exists
    Events.OnGameStart.Add(registerCommands)

    -- Also register for immediate use if in game
    if getPlayer() then
        registerCommands()
    end
end

print("[Zombify] Loaded successfully!")