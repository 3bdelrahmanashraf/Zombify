-- Zombify Main Client Module
-- Music player integration for Project Zomboid

Zombify = Zombify or {}
Zombify.version = "1.0.0"
Zombify.modName = "Zombify"

-- Configuration (loaded from ModData, defaults from ZombifyShared)
Zombify.Config = Zombify.Config or {}
Zombify.State = Zombify.State or {}

-- Initialize the mod
function Zombify.init()
    print("[Zombify] Initializing v" .. Zombify.version)

    -- Load saved configuration
    Zombify.loadConfig()

    -- Load required modules
    require "ZombifyController"
    require "ZombifyMusicPlayer"

    -- Register events
    Events.OnGameStart.Add(Zombify.onGameStart)
    Events.OnTick.Add(Zombify.onTick)
    Events.OnKeyPressed.Add(Zombify.onKeyPressed)
    Events.OnInitGlobalModData.Add(Zombify.init)

    -- Add to Mod Options if available
    if ModOptions and ModOptions.getInstance then
        Zombify.createModOptions()
    end

    -- Initialize music player connection
    Zombify.initMusicPlayer()

    print("[Zombify] Initialized successfully")
end

-- Load configuration from save file
function Zombify.loadConfig()
    local savedData = ModData.getOrCreate("Zombify")
    if savedData and savedData.config then
        for k, v in pairs(savedData.config) do
            Zombify.Config[k] = v
        end
    end
    -- Ensure all defaults exist
    if not ZombifyShared then
        require "ZombifyShared"
    end
    for k, v in pairs(ZombifyShared.DefaultConfig) do
        if Zombify.Config[k] == nil then
            Zombify.Config[k] = v
        end
    end
end

-- Save configuration to save file
function Zombify.saveConfig()
    local savedData = ModData.getOrCreate("Zombify")
    savedData.config = Zombify.Config
    ModData.transmit("Zombify")
end

-- Game start event
function Zombify.onGameStart()
    print("[Zombify] Game started")
    Zombify.State.isVisible = Zombify.Config.enabled and Zombify.Config.modMode ~= "Disabled"
    Zombify.initMusicPlayer()
    ZombifyUI.createOverlay()
end

-- Tick event - update music info periodically
function Zombify.onTick()
    if not Zombify.Config.enabled or Zombify.Config.modMode == "Disabled" then
        return
    end

    local currentTime = getTimestampMs()
    if currentTime - (Zombify.State.lastUpdate or 0) > 1000 then -- Update every second
        Zombify.updateMusicInfo()
        Zombify.State.lastUpdate = currentTime
        ZombifyUI.updateOverlay()
    end
end

-- Key pressed event - FIXED: Proper key handling
function Zombify.onKeyPressed(key)
    if not Zombify.Config.enabled then return end

    -- Check each keybind directly
    if key == Zombify.Config.keybindToggle then
        Zombify.toggleOverlay()
    elseif key == Zombify.Config.keybindPlayPause then
        Zombify.controlPlayPause()
    elseif key == Zombify.Config.keybindNext then
        Zombify.controlNext()
    elseif key == Zombify.Config.keybindPrev then
        Zombify.controlPrev()
    elseif key == Zombify.Config.keybindVolumeUp then
        Zombify.controlVolumeUp()
    elseif key == Zombify.Config.keybindVolumeDown then
        Zombify.controlVolumeDown()
    end
end

-- Initialize music player connection
function Zombify.initMusicPlayer()
    if Zombify.Config.modMode == "Spotify" then
        Zombify.connectSpotify()
    elseif Zombify.Config.modMode == "YouTubeMusic" then
        Zombify.connectYouTubeMusic()
    elseif Zombify.Config.modMode == "Local" then
        Zombify.connectLocal()
    end
end

-- Connect to Spotify via external controller
function Zombify.connectSpotify()
    print("[Zombify] Connecting to Spotify via controller...")
    ZombifyMusicPlayer.connect("spotify")
end

-- Connect to YouTube Music via external controller
function Zombify.connectYouTubeMusic()
    print("[Zombify] Connecting to YouTube Music via controller...")
    ZombifyMusicPlayer.connect("youtubemusic")
end

-- Connect to local music player
function Zombify.connectLocal()
    print("[Zombify] Initializing local music player...")
    ZombifyMusicPlayer.connect("local")
end

-- Update music information from connected player
function Zombify.updateMusicInfo()
    ZombifyMusicPlayer.update()
end

-- Toggle overlay visibility
function Zombify.toggleOverlay()
    Zombify.State.isVisible = not Zombify.State.isVisible
    print("[Zombify] Overlay " .. (Zombify.State.isVisible and "shown" or "hidden"))
    if ZombifyUI.instance then
        ZombifyUI.instance:setVisible(Zombify.State.isVisible)
    end
end

-- Playback controls
function Zombify.controlPlayPause()
    ZombifyMusicPlayer.sendCommand("play_pause")
end

function Zombify.controlNext()
    ZombifyMusicPlayer.sendCommand("next")
end

function Zombify.controlPrev()
    ZombifyMusicPlayer.sendCommand("previous")
end

function Zombify.controlVolumeUp()
    ZombifyMusicPlayer.sendCommand("volume", {delta = 0.1})
end

function Zombify.controlVolumeDown()
    ZombifyMusicPlayer.sendCommand("volume", {delta = -0.1})
end

-- Create Mod Options panel - FIXED: Proper ModOptions integration
function Zombify.createModOptions()
    if not ModOptions or not ModOptions.getInstance then
        print("[Zombify] ModOptions not available, skipping options panel creation")
        return
    end

    local options = ModOptions:getInstance(Zombify.modName)
    if not options then
        options = ModOptions:new(Zombify.modName, "Zombify")
        ModOptions:add(options)
    end

    -- Enabled toggle
    options:addTickBox("Enabled", "ZombifyConfig", "enabled", "Enable Zombify overlay")

    -- Music player mode
    local modeOptions = {"Disabled", "Spotify", "YouTubeMusic", "Local"}
    options:addComboBox("Music Player", "ZombifyConfig", "modMode", modeOptions, "Select music player to integrate")

    -- Display settings
    local anchorOptions = {"TopLeft", "TopCenter", "TopRight", "CenterLeft", "Center", "CenterRight", "BottomLeft", "BottomCenter", "BottomRight"}
    options:addComboBox("Anchor Point", "ZombifyConfig", "anchorPoint", anchorOptions, "Position of the overlay")

    options:addSlider("X Offset", "ZombifyConfig", "xOffset", -500, 500, 1, "Horizontal offset from anchor")
    options:addSlider("Y Offset", "ZombifyConfig", "yOffset", -500, 500, 1, "Vertical offset from anchor")
    options:addSlider("Scale", "ZombifyConfig", "scale", 0.5, 2.0, 0.1, "Overlay scale")

    local renderOptions = {"Always", "WhenPlaying", "WhenPaused", "InVehicle", "InMenu"}
    options:addComboBox("Render Type", "ZombifyConfig", "renderType", renderOptions, "When to show the overlay")

    local displayOptions = {"Full", "Compact", "Minimal"}
    options:addComboBox("Display Mode", "ZombifyConfig", "displayMode", displayOptions, "How much info to show")

    options:addTickBox("Show Album Art", "ZombifyConfig", "showAlbumArt", "Display album artwork")
    options:addTickBox("Show Progress Bar", "ZombifyConfig", "showProgressBar", "Display playback progress")
    options:addTickBox("Show Controls", "ZombifyConfig", "showControls", "Display playback controls")

    -- Theme
    local themeOptions = {"Default", "Dark", "Light", "Transparent"}
    options:addComboBox("Theme", "ZombifyConfig", "theme", themeOptions, "Visual theme")

    -- Spotify settings
    options:addTextEntry("Spotify Client ID", "ZombifyConfig", "spotifyClientId", "Your Spotify app client ID")
    options:addTextEntry("Spotify Client Secret", "ZombifyConfig", "spotifyClientSecret", "Your Spotify app client secret")

    -- Controller settings
    options:addTextEntry("Controller Host", "ZombifyConfig", "controllerHost", "External controller host (default: 127.0.0.1)")
    options:addTickBox("Auto-start Controller", "ZombifyConfig", "controllerAutoStart", "Automatically start external controller")

    -- Keybinds
    options:addKeyBinding("Toggle Overlay", "ZombifyConfig", "keybindToggle", "Key to toggle overlay visibility")
    options:addKeyBinding("Play/Pause", "ZombifyConfig", "keybindPlayPause", "Play/pause key")
    options:addKeyBinding("Next Track", "ZombifyConfig", "keybindNext", "Next track key")
    options:addKeyBinding("Previous Track", "ZombifyConfig", "keybindPrev", "Previous track key")
    options:addKeyBinding("Volume Up", "ZombifyConfig", "keybindVolumeUp", "Volume up key")
    options:addKeyBinding("Volume Down", "ZombifyConfig", "keybindVolumeDown", "Volume down key")
end

-- Get overlay position based on anchor
function Zombify.getOverlayPosition()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local ow = 300 * Zombify.Config.scale
    local oh = 100 * Zombify.Config.scale

    local x, y = 0, 0

    if Zombify.Config.anchorPoint == "TopLeft" then
        x, y = 10 + Zombify.Config.xOffset, 10 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "TopCenter" then
        x, y = (sw - ow) / 2 + Zombify.Config.xOffset, 10 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "TopRight" then
        x, y = sw - ow - 10 + Zombify.Config.xOffset, 10 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "CenterLeft" then
        x, y = 10 + Zombify.Config.xOffset, (sh - oh) / 2 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "Center" then
        x, y = (sw - ow) / 2 + Zombify.Config.xOffset, (sh - oh) / 2 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "CenterRight" then
        x, y = sw - ow - 10 + Zombify.Config.xOffset, (sh - oh) / 2 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "BottomLeft" then
        x, y = 10 + Zombify.Config.xOffset, sh - oh - 10 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "BottomCenter" then
        x, y = (sw - ow) / 2 + Zombify.Config.xOffset, sh - oh - 10 + Zombify.Config.yOffset
    elseif Zombify.Config.anchorPoint == "BottomRight" then
        x, y = sw - ow - 10 + Zombify.Config.xOffset, sh - oh - 10 + Zombify.Config.yOffset
    end

    return x, y, ow, oh
end

-- Initialize
Events.OnInitGlobalModData.Add(Zombify.init)