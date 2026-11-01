-- Zombify Settings Panel
-- Standalone configuration UI for the mod (opened via /zombify settings)

ZombifySettings = ZombifySettings or {}

-- Create settings panel
function ZombifySettings.createPanel()
    local panel = ISPanelJoypad:new(0, 0, 600, 500)
    panel:initialise()
    panel:setAnchorLeft(true)
    panel:setAnchorRight(true)
    panel:setAnchorTop(true)
    panel:setAnchorBottom(true)
    panel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.95}

    local y = 20

    -- Title
    local title = ISLabel:new(20, y, 30, "Zombify Settings", 1, 0.8, 0, 1, UIFont.Large, true)
    title:initialise()
    panel:addChild(title)
    y = y + 40

    -- General Section
    y = ZombifySettings.addSection(panel, y, "General")

    -- Enabled
    y = ZombifySettings.addTickBox(panel, y, "Enable Zombify", "enabled")

    -- Music Player Mode
    y = ZombifySettings.addComboBox(panel, y, "Music Player",
        {"Disabled", "Spotify", "YouTubeMusic", "Local"},
        "modMode")

    y = y + 10

    -- Display Section
    y = ZombifySettings.addSection(panel, y, "Display")

    -- Anchor Point
    y = ZombifySettings.addComboBox(panel, y, "Anchor Point",
        {"TopLeft", "TopCenter", "TopRight", "CenterLeft", "Center", "CenterRight", "BottomLeft", "BottomCenter", "BottomRight"},
        "anchorPoint")

    -- Offsets
    y = ZombifySettings.addSlider(panel, y, "X Offset", "xOffset", -500, 500, 1)
    y = ZombifySettings.addSlider(panel, y, "Y Offset", "yOffset", -500, 500, 1)
    y = ZombifySettings.addSlider(panel, y, "Scale", "scale", 0.5, 2.0, 0.1)

    -- Render Type
    y = ZombifySettings.addComboBox(panel, y, "Show When",
        {"Always", "WhenPlaying", "WhenPaused", "InVehicle", "InMenu"},
        "renderType")

    -- Display Mode
    y = ZombifySettings.addComboBox(panel, y, "Display Mode",
        {"Full", "Compact", "Minimal"},
        "displayMode")

    y = y + 10

    -- Visibility Options
    y = ZombifySettings.addSection(panel, y, "Visibility Options")
    y = ZombifySettings.addTickBox(panel, y, "Show Album Art", "showAlbumArt")
    y = ZombifySettings.addTickBox(panel, y, "Show Progress Bar", "showProgressBar")
    y = ZombifySettings.addTickBox(panel, y, "Show Controls", "showControls")

    y = y + 10

    -- Theme Section
    y = ZombifySettings.addSection(panel, y, "Theme")
    y = ZombifySettings.addComboBox(panel, y, "Theme",
        {"Default", "Dark", "Light", "Transparent"},
        "theme")

    y = y + 10

    -- Spotify Section
    y = ZombifySettings.addSection(panel, y, "Spotify Settings")
    y = ZombifySettings.addTextEntry(panel, y, "Client ID", "spotifyClientId", "Your Spotify app client ID")
    y = ZombifySettings.addTextEntry(panel, y, "Client Secret", "spotifyClientSecret", "Your Spotify app client secret")

    -- Controller Section
    y = ZombifySettings.addSection(panel, y, "External Controller")
    y = ZombifySettings.addTextEntry(panel, y, "Controller Host", "controllerHost", "External controller host (default: 127.0.0.1)")
    y = ZombifySettings.addTickBox(panel, y, "Auto-start Controller", "controllerAutoStart")

    y = y + 10

    -- Keybinds Section
    y = ZombifySettings.addSection(panel, y, "Keybinds")
    y = ZombifySettings.addKeyBinding(panel, y, "Toggle Overlay", "keybindToggle")
    y = ZombifySettings.addKeyBinding(panel, y, "Play/Pause", "keybindPlayPause")
    y = ZombifySettings.addKeyBinding(panel, y, "Next Track", "keybindNext")
    y = ZombifySettings.addKeyBinding(panel, y, "Previous Track", "keybindPrev")
    y = ZombifySettings.addKeyBinding(panel, y, "Volume Up", "keybindVolumeUp")
    y = ZombifySettings.addKeyBinding(panel, y, "Volume Down", "keybindVolumeDown")

    -- Buttons
    y = y + 20
    local saveBtn = ISButton:new(20, y, 100, 30, "Save", panel, ZombifySettings.onSave)
    saveBtn:initialise()
    panel:addChild(saveBtn)

    local resetBtn = ISButton:new(140, y, 100, 30, "Reset to Defaults", panel, ZombifySettings.onReset)
    resetBtn:initialise()
    panel:addChild(resetBtn)

    local closeBtn = ISButton:new(480, y, 100, 30, "Close", panel, ZombifySettings.onClose)
    closeBtn:initialise()
    panel:addChild(closeBtn)

    panel.settingsPanel = panel
    return panel
end

-- Helper functions for creating UI elements
function ZombifySettings.addSection(panel, y, title)
    local label = ISLabel:new(20, y, 25, title, 1, 0.8, 0, 1, UIFont.Medium, true)
    label:initialise()
    panel:addChild(label)
    return y + 30
end

function ZombifySettings.addTickBox(panel, y, label, configKey)
    local tickBox = ISTickBox:new(20, y, 200, 25, label, panel, ZombifySettings.onTickBoxChange)
    tickBox:initialise()
    tickBox:addOption(label)
    tickBox:setSelected(1, Zombify.Config[configKey] == true)
    tickBox.configKey = configKey
    panel:addChild(tickBox)
    return y + 30
end

function ZombifySettings.addComboBox(panel, y, label, options, configKey)
    local labelObj = ISLabel:new(20, y, 20, label, 1, 1, 1, 1, UIFont.Small, true)
    labelObj:initialise()
    panel:addChild(labelObj)

    local combo = ISComboBox:new(200, y - 2, 200, 25, panel, ZombifySettings.onComboChange)
    combo:initialise()
    for _, opt in ipairs(options) do
        combo:addOption(opt)
    end
    combo:setSelected(Zombify.Config[configKey])
    combo.configKey = configKey
    panel:addChild(combo)

    return y + 30
end

function ZombifySettings.addSlider(panel, y, label, configKey, min, max, step)
    local labelObj = ISLabel:new(20, y, 20, label .. ": " .. tostring(Zombify.Config[configKey]), 1, 1, 1, 1, UIFont.Small, true)
    labelObj:initialise()
    panel:addChild(labelObj)

    local slider = ISSliderPanel:new(200, y - 2, 200, 25, panel, ZombifySettings.onSliderChange)
    slider:initialise()
    slider:setValues(min, max, step, Zombify.Config[configKey] or min)
    slider.configKey = configKey
    slider.label = labelObj
    panel:addChild(slider)

    return y + 30
end

function ZombifySettings.addTextEntry(panel, y, label, configKey, tooltip)
    local labelObj = ISLabel:new(20, y, 20, label, 1, 1, 1, 1, UIFont.Small, true)
    labelObj:initialise()
    panel:addChild(labelObj)

    local entry = ISTextEntryBox:new(Zombify.Config[configKey] or "", 200, y - 2, 200, 25)
    entry:initialise()
    entry:setTooltip(tooltip)
    entry.configKey = configKey
    entry.onTextChange = ZombifySettings.onTextChange
    panel:addChild(entry)

    return y + 30
end

function ZombifySettings.addKeyBinding(panel, y, label, configKey)
    local labelObj = ISLabel:new(20, y, 20, label, 1, 1, 1, 1, UIFont.Small, true)
    labelObj:initialise()
    panel:addChild(labelObj)

    local keybind = ISKeyBinding:new(200, y - 2, 200, 25, panel, ZombifySettings.onKeybindChange)
    keybind:initialise()
    keybind:setKey(Zombify.Config[configKey])
    keybind.configKey = configKey
    panel:addChild(keybind)

    return y + 30
end

-- Callbacks
function ZombifySettings.onTickBoxChange(tickBox, index, selected)
    Zombify.Config[tickBox.configKey] = selected
    Zombify.saveConfig()
end

function ZombifySettings.onComboChange(combo)
    Zombify.Config[combo.configKey] = combo:getOptionText(combo.selected)
    Zombify.saveConfig()
    -- Refresh UI if overlay exists
    if ZombifyUI.instance then
        ZombifyUI.updateOverlay()
    end
end

function ZombifySettings.onSliderChange(slider, value)
    Zombify.Config[slider.configKey] = value
    slider.label:setName(slider.label.name:gsub(":.*", "") .. ": " .. string.format("%.1f", value))
    Zombify.saveConfig()
    if ZombifyUI.instance then
        ZombifyUI.updateOverlay()
    end
end

function ZombifySettings.onTextChange(entry)
    Zombify.Config[entry.configKey] = entry:getText()
    Zombify.saveConfig()
end

function ZombifySettings.onKeybindChange(keybind, key)
    Zombify.Config[keybind.configKey] = key
    Zombify.saveConfig()
end

function ZombifySettings.onSave(button)
    Zombify.saveConfig()
    print("[Zombify] Settings saved")
end

function ZombifySettings.onReset(button)
    -- Reset to defaults
    Zombify.Config = ZombifyShared.deepCopy(ZombifyShared.DefaultConfig)
    Zombify.saveConfig()
    print("[Zombify] Settings reset to defaults")
    -- Close and reopen to refresh
    if ZombifySettings.currentPanel then
        ZombifySettings.currentPanel:removeFromUIManager()
        ZombifySettings.open()
    end
end

function ZombifySettings.onClose(button)
    if ZombifySettings.currentPanel then
        ZombifySettings.currentPanel:removeFromUIManager()
        ZombifySettings.currentPanel = nil
    end
end

-- Open settings panel
function ZombifySettings.open()
    local panel = ZombifySettings.createPanel()
    panel:setX((getCore():getScreenWidth() - 600) / 2)
    panel:setY((getCore():getScreenHeight() - 500) / 2)
    ZombifySettings.currentPanel = panel
    getPlayer():getUIManager():AddUI(panel)
end