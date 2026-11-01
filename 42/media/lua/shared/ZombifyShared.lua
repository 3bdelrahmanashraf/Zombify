-- Zombify Shared Module
-- Common functions and data structures shared between client and server

ZombifyShared = ZombifyShared or {}

-- Music player status enum
ZombifyShared.PlayerStatus = {
    DISCONNECTED = "Disconnected",
    CONNECTING = "Connecting",
    CONNECTED = "Connected",
    ERROR = "Error",
}

-- Supported music players
ZombifyShared.Players = {
    {
        id = "spotify",
        name = "Spotify",
        requiresAuth = true,
        supportsPlaybackControl = true,
        supportsAlbumArt = true,
        supportsLyrics = false,
        authType = "oauth2",
        controllerPort = 8765,
    },
    {
        id = "youtubemusic",
        name = "YouTube Music",
        requiresAuth = false,
        supportsPlaybackControl = true,
        supportsAlbumArt = true,
        supportsLyrics = false,
        authType = "none",
        controllerPort = 8766,
    },
    {
        id = "local",
        name = "Local Files",
        requiresAuth = false,
        supportsPlaybackControl = true,
        supportsAlbumArt = false,
        supportsLyrics = false,
        authType = "none",
        controllerPort = 0,
    },
}

-- Default configuration
ZombifyShared.DefaultConfig = {
    enabled = true,
    modMode = "Disabled",
    anchorPoint = "BottomRight",
    xOffset = 0,
    yOffset = 0,
    scale = 1.0,
    renderType = "Always",
    displayMode = "Full",
    showAlbumArt = true,
    showProgressBar = true,
    showControls = true,
    autoHide = false,
    autoHideDelay = 5,
    theme = "Default",
    spotifyClientId = "",
    spotifyClientSecret = "",
    ytmEnabled = false,
    localMusicPath = "",
    keybindToggle = "KEY_F10",
    keybindPlayPause = "KEY_MEDIA_PLAY_PAUSE",
    keybindNext = "KEY_MEDIA_NEXT",
    keybindPrev = "KEY_MEDIA_PREV",
    keybindVolumeUp = "KEY_MEDIA_VOLUME_UP",
    keybindVolumeDown = "KEY_MEDIA_VOLUME_DOWN",
    controllerHost = "127.0.0.1",
    controllerAutoStart = true,
}

-- Anchor points for overlay positioning
ZombifyShared.AnchorPoints = {
    TopLeft = {x = 0, y = 0},
    TopCenter = {x = 0.5, y = 0},
    TopRight = {x = 1, y = 0},
    CenterLeft = {x = 0, y = 0.5},
    Center = {x = 0.5, y = 0.5},
    CenterRight = {x = 1, y = 0.5},
    BottomLeft = {x = 0, y = 1},
    BottomCenter = {x = 0.5, y = 1},
    BottomRight = {x = 1, y = 1},
}

-- Render types
ZombifyShared.RenderTypes = {
    Always = "Always",
    WhenPlaying = "WhenPlaying",
    WhenPaused = "WhenPaused",
    InVehicle = "InVehicle",
    InMenu = "InMenu",
}

-- Display modes
ZombifyShared.DisplayModes = {
    Full = "Full",
    Compact = "Compact",
    Minimal = "Minimal",
}

-- Themes
ZombifyShared.Themes = {
    Default = "Default",
    Dark = "Dark",
    Light = "Light",
    Transparent = "Transparent",
}

-- Get theme colors
function ZombifyShared.getThemeColors(theme)
    local themes = {
        Default = {
            background = {r=0, g=0, b=0, a=0.7},
            border = {r=0.5, g=0.5, b=0.5, a=1},
            text = {r=1, g=1, b=1, a=1},
            textSecondary = {r=0.8, g=0.8, b=0.8, a=1},
            textMuted = {r=0.6, g=0.6, b=0.6, a=1},
            accent = {r=0.2, g=0.7, b=0.3, a=1},
            progressBg = {r=0.2, g=0.2, b=0.2, a=0.8},
            progressFg = {r=0.2, g=0.7, b=0.3, a=1},
        },
        Dark = {
            background = {r=0.1, g=0.1, b=0.1, a=0.9},
            border = {r=0.3, g=0.3, b=0.3, a=1},
            text = {r=1, g=1, b=1, a=1},
            textSecondary = {r=0.9, g=0.9, b=0.9, a=1},
            textMuted = {r=0.7, g=0.7, b=0.7, a=1},
            accent = {r=0.1, g=0.6, b=0.9, a=1},
            progressBg = {r=0.15, g=0.15, b=0.15, a=0.9},
            progressFg = {r=0.1, g=0.6, b=0.9, a=1},
        },
        Light = {
            background = {r=0.95, g=0.95, b=0.95, a=0.9},
            border = {r=0.7, g=0.7, b=0.7, a=1},
            text = {r=0.1, g=0.1, b=0.1, a=1},
            textSecondary = {r=0.3, g=0.3, b=0.3, a=1},
            textMuted = {r=0.5, g=0.5, b=0.5, a=1},
            accent = {r=0.0, g=0.5, b=0.0, a=1},
            progressBg = {r=0.8, g=0.8, b=0.8, a=0.8},
            progressFg = {r=0.0, g=0.5, b=0.0, a=1},
        },
        Transparent = {
            background = {r=0, g=0, b=0, a=0.3},
            border = {r=0.5, g=0.5, b=0.5, a=0.5},
            text = {r=1, g=1, b=1, a=1},
            textSecondary = {r=0.9, g=0.9, b=0.9, a=1},
            textMuted = {r=0.7, g=0.7, b=0.7, a=1},
            accent = {r=0.2, g=0.7, b=0.3, a=1},
            progressBg = {r=0.1, g=0.1, b=0.1, a=0.5},
            progressFg = {r=0.2, g=0.7, b=0.3, a=1},
        },
    }
    return themes[theme] or themes.Default
end

-- Format time in milliseconds to MM:SS
function ZombifyShared.formatTime(ms)
    if not ms or ms < 0 then return "0:00" end
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- Format time in milliseconds to HH:MM:SS
function ZombifyShared.formatTimeLong(ms)
    if not ms or ms < 0 then return "0:00:00" end
    local totalSeconds = math.floor(ms / 1000)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%d:%02d", minutes, seconds)
    end
end

-- Calculate progress percentage
function ZombifyShared.getProgress(current, total)
    if not total or total <= 0 then return 0 end
    return math.min(math.max(current / total, 0), 1)
end

-- Validate config
function ZombifyShared.validateConfig(config)
    local valid = {}
    for k, v in pairs(ZombifyShared.DefaultConfig) do
        if config[k] ~= nil then
            valid[k] = config[k]
        else
            valid[k] = v
        end
    end
    return valid
end

-- Deep copy table
function ZombifyShared.deepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = ZombifyShared.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Merge tables
function ZombifyShared.mergeTables(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            ZombifyShared.mergeTables(target[k], v)
        else
            target[k] = v
        end
    end
end

-- Get player by ID
function ZombifyShared.getPlayerByID(id)
    return getPlayer(id)
end

-- Check if in vehicle
function ZombifyShared.isInVehicle()
    local player = getPlayer()
    return player and player:getVehicle() ~= nil
end

-- Check if any UI is open
function ZombifyShared.isAnyUIOpen()
    local player = getPlayer()
    return player and player:getUIManager() and player:getUIManager():isAnyUIOpen()
end