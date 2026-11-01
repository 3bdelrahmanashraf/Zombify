-- Zombify Settings Panel
-- Standalone configuration UI with integrated controller management

ZombifySettings = ZombifySettings or {}
ZombifySettings.controllerPanel = nil
ZombifySettings.controllerLogLines = {}
ZombifySettings.maxLogLines = 50

-- Create settings panel
function ZombifySettings.createPanel()
    local panel = ISPanelJoypad:new(0, 0, 700, 650)
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

    -- ========================================
    -- CONTROLLER MANAGEMENT SECTION
    -- ========================================
    y = ZombifySettings.addSection(panel, y, "Controller Management")

    -- Controller Status
    ZombifySettings.statusLabel = ISLabel:new(20, y, 25, "Controller: Checking...", 1, 1, 1, 1, UIFont.Medium, true)
    ZombifySettings.statusLabel:initialise()
    panel:addChild(ZombifySettings.statusLabel)
    y = y + 30

    -- Controller Buttons Row
    local btnX = 20
    local btnW = 140
    local btnH = 28
    local btnGap = 10

    ZombifySettings.startBtn = ISButton:new(btnX, y, btnW, btnH, "Start Controller", panel, ZombifySettings.onStartController)
    ZombifySettings.startBtn:initialise()
    panel:addChild(ZombifySettings.startBtn)

    ZombifySettings.stopBtn = ISButton:new(btnX + btnW + btnGap, y, btnW, btnH, "Stop Controller", panel, ZombifySettings.onStopController)
    ZombifySettings.stopBtn:initialise()
    panel:addChild(ZombifySettings.stopBtn)

    ZombifySettings.restartBtn = ISButton:new(btnX + (btnW + btnGap) * 2, y, btnW, btnH, "Restart Controller", panel, ZombifySettings.onRestartController)
    ZombifySettings.restartBtn:initialise()
    panel:addChild(ZombifySettings.restartBtn)

    ZombifySettings.openLogBtn = ISButton:new(btnX + (btnW + btnGap) * 3, y, btnW, btnH, "Open Log Folder", panel, ZombifySettings.onOpenLogFolder)
    ZombifySettings.openLogBtn:initialise()
    panel:addChild(ZombifySettings.openLogBtn)

    y = y + 35

    -- Spotify Authentication
    ZombifySettings.spotifyAuthBtn = ISButton:new(btnX, y, btnW, btnH, "Authenticate Spotify", panel, ZombifySettings.onSpotifyAuth)
    ZombifySettings.spotifyAuthBtn:initialise()
    panel:addChild(ZombifySettings.spotifyAuthBtn)

    ZombifySettings.spotifyStatusLabel = ISLabel:new(btnX + btnW + btnGap, y + 5, 25, "Spotify: Not authenticated", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    ZombifySettings.spotifyStatusLabel:initialise()
    panel:addChild(ZombifySettings.spotifyStatusLabel)

    ZombifySettings.ytmusicBtn = ISButton:new(btnX + (btnW + btnGap) * 2, y, btnW, btnH, "Setup YouTube Music", panel, ZombifySettings.onYTMusicSetup)
    ZombifySettings.ytmusicBtn:initialise()
    panel:addChild(ZombifySettings.ytmusicBtn)

    ZombifySettings.ytmusicStatusLabel = ISLabel:new(btnX + (btnW + btnGap) * 3, y + 5, 25, "YouTube Music: Not configured", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    ZombifySettings.ytmusicStatusLabel:initialise()
    panel:addChild(ZombifySettings.ytmusicStatusLabel)

    y = y + 35

    -- Controller Config
    ZombifySettings.autoStartTick = ISTickBox:new(20, y, 200, 25, "Auto-start controller with game", panel, ZombifySettings.onTickBoxChange)
    ZombifySettings.autoStartTick:initialise()
    ZombifySettings.autoStartTick:addOption("Auto-start controller with game")
    ZombifySettings.autoStartTick:setSelected(1, Zombify.Config.controllerAutoStart == true)
    ZombifySettings.autoStartTick.configKey = "controllerAutoStart"
    panel:addChild(ZombifySettings.autoStartTick)

    y = y + 30

    y = ZombifySettings.addTextEntry(panel, y, "Controller Host", "controllerHost", "Controller host (default: 127.0.0.1)")
    y = ZombifySettings.addTextEntry(panel, y, "Controller Port", "controllerPort", "Controller WebSocket port (default: 8765)")

    y = y + 10

    -- Controller Log Display
    y = ZombifySettings.addSection(panel, y, "Controller Log")

    ZombifySettings.logPanel = ISPanel:new(20, y, 660, 150)
    ZombifySettings.logPanel:initialise()
    ZombifySettings.logPanel.backgroundColor = {r=0, g=0, b=0, a=0.5}
    ZombifySettings.logPanel.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
    ZombifySettings.logPanel:noBackground()
    ZombifySettings.logPanel.prerender = function(self)
        self:drawRect(0, 0, self.width, self.height, 0.5, 0, 0, 0)
        self:drawRectBorder(0, 0, self.width, self.height, 1, 0.3, 0.3, 0.3)
    end
    panel:addChild(ZombifySettings.logPanel)

    -- Log text area (using a label that we update)
    ZombifySettings.logLabel = ISLabel:new(10, 10, 130, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    ZombifySettings.logLabel:initialise()
    ZombifySettings.logLabel.maxLines = 20
    ZombifySettings.logPanel:addChild(ZombifySettings.logLabel)

    -- Clear log button
    ZombifySettings.clearLogBtn = ISButton:new(20, y + 155, 100, 25, "Clear Log", panel, ZombifySettings.onClearLog)
    ZombifySettings.clearLogBtn:initialise()
    panel:addChild(ZombifySettings.clearLogBtn)

    y = y + 185

    -- ========================================
    -- GENERAL SETTINGS SECTION
    -- ========================================
    y = ZombifySettings.addSection(panel, y, "General")

    -- Enabled
    y = ZombifySettings.addTickBox(panel, y, "Enable Zombify", "enabled")

    -- Music Player Mode
    y = ZombifySettings.addComboBox(panel, y, "Music Player",
        {"Disabled", "Spotify", "YouTubeMusic", "Local"},
        "modMode")

    y = y + 10

    -- ========================================
    -- DISPLAY SECTION
    -- ========================================
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

    -- ========================================
    -- THEME SECTION
    -- ========================================
    y = ZombifySettings.addSection(panel, y, "Theme")
    y = ZombifySettings.addComboBox(panel, y, "Theme",
        {"Default", "Dark", "Light", "Transparent"},
        "theme")

    y = y + 10

    -- ========================================
    -- SPOTIFY SETTINGS
    -- ========================================
    y = ZombifySettings.addSection(panel, y, "Spotify API Credentials")
    y = ZombifySettings.addTextEntry(panel, y, "Client ID", "spotifyClientId", "Your Spotify app client ID from developer.spotify.com")
    y = ZombifySettings.addTextEntry(panel, y, "Client Secret", "spotifyClientSecret", "Your Spotify app client secret")

    y = y + 10

    -- ========================================
    -- KEYBINDS SECTION
    -- ========================================
    y = ZombifySettings.addSection(panel, y, "Keybinds")
    y = ZombifySettings.addKeyBinding(panel, y, "Toggle Overlay", "keybindToggle")
    y = ZombifySettings.addKeyBinding(panel, y, "Play/Pause", "keybindPlayPause")
    y = ZombifySettings.addKeyBinding(panel, y, "Next Track", "keybindNext")
    y = ZombifySettings.addKeyBinding(panel, y, "Previous Track", "keybindPrev")
    y = ZombifySettings.addKeyBinding(panel, y, "Volume Up", "keybindVolumeUp")
    y = ZombifySettings.addKeyBinding(panel, y, "Volume Down", "keybindVolumeDown")

    -- ========================================
    -- BOTTOM BUTTONS
    -- ========================================
    y = y + 20
    local saveBtn = ISButton:new(20, y, 100, 30, "Save All", panel, ZombifySettings.onSave)
    saveBtn:initialise()
    panel:addChild(saveBtn)

    local resetBtn = ISButton:new(140, y, 100, 30, "Reset to Defaults", panel, ZombifySettings.onReset)
    resetBtn:initialise()
    panel:addChild(resetBtn)

    local testBtn = ISButton:new(260, y, 100, 30, "Test Connection", panel, ZombifySettings.onTestConnection)
    testBtn:initialise()
    panel:addChild(testBtn)

    local closeBtn = ISButton:new(580, y, 100, 30, "Close", panel, ZombifySettings.onClose)
    closeBtn:initialise()
    panel:addChild(closeBtn)

    panel.settingsPanel = panel
    ZombifySettings.currentPanel = panel

    -- Start status update timer
    ZombifySettings.startStatusUpdates()

    return panel
end

-- Start periodic status updates
function ZombifySettings.startStatusUpdates()
    if ZombifySettings.statusUpdateTimer then
        return
    end
    ZombifySettings.statusUpdateTimer = true
    Events.OnTick.Add(ZombifySettings.updateStatusDisplay)
end

-- Update status display periodically
function ZombifySettings.updateStatusDisplay()
    if not ZombifySettings.currentPanel then
        Events.OnTick.Remove(ZombifySettings.updateStatusDisplay)
        ZombifySettings.statusUpdateTimer = false
        return
    end

    -- Update controller status
    local running = ZombifyController and ZombifyController.isRunning() or false
    if ZombifySettings.statusLabel then
        if running then
            ZombifySettings.statusLabel:setName("Controller: Running (ws://" .. (Zombify.Config.controllerHost or "127.0.0.1") .. ":" .. (Zombify.Config.controllerPort or "8765") .. ")")
            ZombifySettings.statusLabel.r, ZombifySettings.statusLabel.g, ZombifySettings.statusLabel.b = 0.2, 0.8, 0.2
        else
            ZombifySettings.statusLabel:setName("Controller: Stopped")
            ZombifySettings.statusLabel.r, ZombifySettings.statusLabel.g, ZombifySettings.statusLabel.b = 0.8, 0.2, 0.2
        end
    end

    -- Update Spotify status
    if ZombifySettings.spotifyStatusLabel then
        local authed = ZombifyController and ZombifyController.isSpotifyAuthenticated() or false
        if authed then
            ZombifySettings.spotifyStatusLabel:setName("Spotify: Authenticated")
            ZombifySettings.spotifyStatusLabel.r, ZombifySettings.spotifyStatusLabel.g, ZombifySettings.spotifyStatusLabel.b = 0.2, 0.8, 0.2
        else
            ZombifySettings.spotifyStatusLabel:setName("Spotify: Not authenticated")
            ZombifySettings.spotifyStatusLabel.r, ZombifySettings.spotifyStatusLabel.g, ZombifySettings.spotifyStatusLabel.b = 0.8, 0.2, 0.2
        end
    end

    -- Update YouTube Music status
    if ZombifySettings.ytmusicStatusLabel then
        local configured = ZombifyController and ZombifyController.isYTMusicConfigured() or false
        if configured then
            ZombifySettings.ytmusicStatusLabel:setName("YouTube Music: Configured")
            ZombifySettings.ytmusicStatusLabel.r, ZombifySettings.ytmusicStatusLabel.g, ZombifySettings.ytmusicStatusLabel.b = 0.2, 0.8, 0.2
        else
            ZombifySettings.ytmusicStatusLabel:setName("YouTube Music: Not configured")
            ZombifySettings.ytmusicStatusLabel.r, ZombifySettings.ytmusicStatusLabel.g, ZombifySettings.ytmusicStatusLabel.b = 0.8, 0.2, 0.2
        end
    end

    -- Update log display
    ZombifySettings.updateLogDisplay()
end

-- Update log display
function ZombifySettings.updateLogDisplay()
    if ZombifySettings.logLabel and #ZombifySettings.controllerLogLines > 0 then
        local displayLines = {}
        local start = math.max(1, #ZombifySettings.controllerLogLines - 15)
        for i = start, #ZombifySettings.controllerLogLines do
            table.insert(displayLines, ZombifySettings.controllerLogLines[i])
        end
        ZombifySettings.logLabel:setName(table.concat(displayLines, "\n"))
    end
end

-- Add log entry
function ZombifySettings.addLog(message)
    local timestamp = os.date("%H:%M:%S")
    table.insert(ZombifySettings.controllerLogLines, "[" .. timestamp .. "] " .. message)
    if #ZombifySettings.controllerLogLines > ZombifySettings.maxLogLines then
        table.remove(ZombifySettings.controllerLogLines, 1)
    end
    ZombifySettings.updateLogDisplay()
end

-- Clear log
function ZombifySettings.onClearLog(button)
    ZombifySettings.controllerLogLines = {}
    ZombifySettings.updateLogDisplay()
end

-- Controller button callbacks
function ZombifySettings.onStartController(button)
    ZombifySettings.addLog("Starting controller...")
    if ZombifyController then
        ZombifyController.start()
    end
end

function ZombifySettings.onStopController(button)
    ZombifySettings.addLog("Stopping controller...")
    if ZombifyController then
        ZombifyController.stop()
    end
end

function ZombifySettings.onRestartController(button)
    ZombifySettings.addLog("Restarting controller...")
    if ZombifyController then
        ZombifyController.restart()
    end
end

function ZombifySettings.onOpenLogFolder(button)
    ZombifySettings.addLog("Opening log folder...")
    -- Open the controller log folder
    local path = getFilePath("") .. "controller/"
    if getOS() == "Windows" then
        os.execute('explorer "' .. path .. '"')
    end
end

function ZombifySettings.onSpotifyAuth(button)
    ZombifySettings.addLog("Opening Spotify authentication...")
    if ZombifyController then
        ZombifyController.openSpotifyAuth()
    end
end

function ZombifySettings.onYTMusicSetup(button)
    ZombifySettings.addLog("Opening YouTube Music setup...")
    if ZombifyController then
        ZombifyController.openYTMusicSetup()
    end
end

function ZombifySettings.onTestConnection(button)
    ZombifySettings.addLog("Testing controller connection...")
    if ZombifyController then
        ZombifyController.testConnection()
    end
end

-- ========================================
-- HELPER FUNCTIONS (same as before)
-- ========================================

function ZombifySettings.addSection(panel, y, title)
    local label = ISLabel:new(20, y, 25, title, 1, 0.8, 0, 1, UIFont.Medium, true)
    label:initialise()
    panel:addChild(label)
    return y + 30
end

function ZombifySettings.addTickBox(panel, y, label, configKey)
    local tickBox = ISTickBox:new(20, y, 300, 25, label, panel, ZombifySettings.onTickBoxChange)
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
    if ZombifyUI.instance then
        ZombifyUI.updateOverlay()
    end
end

function ZombifySettings.onSliderChange(slider, value)
    Zombify.Config[slider.configKey] = value
    slider.label:setName(slider.label.name:gsub(":.*", "") .. ": " .. string.format("%.1f", value))
    Zombify.saveConfig()
    if ZombifySettings.currentPanel then
        ZombifySettings.updateStatusDisplay()
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
    ZombifySettings.addLog("Settings saved")
end

function ZombifySettings.onReset(button)
    Zombify.Config = ZombifyShared.deepCopy(ZombifyShared.DefaultConfig)
    Zombify.saveConfig()
    ZombifySettings.addLog("Settings reset to defaults")
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
    Events.OnTick.Remove(ZombifySettings.updateStatusDisplay)
    ZombifySettings.statusUpdateTimer = false
end

-- Open settings panel
function ZombifySettings.open()
    local panel = ZombifySettings.createPanel()
    panel:setX((getCore():getScreenWidth() - 700) / 2)
    panel:setY((getCore():getScreenHeight() - 650) / 2)
    ZombifySettings.currentPanel = panel
    getPlayer():getUIManager():AddUI(panel)
end