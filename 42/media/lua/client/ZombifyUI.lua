-- Zombify UI Module
-- Handles rendering the music player overlay

ZombifyUI = ZombifyUI or {}
ZombifyUI.instance = nil

-- Create the overlay panel
function ZombifyUI.createOverlay()
    if ZombifyUI.instance then
        ZombifyUI.instance:removeFromUIManager()
    end

    local config = Zombify.Config or ZombifyShared.DefaultConfig
    local w = 300 * config.scale
    local h = 100 * config.scale

    local panel = ISPanel:new(0, 0, w, h)
    panel:initialise()
    panel:setVisible(false)
    panel.backgroundColor = {r=0, g=0, b=0, a=0.7}
    panel.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
    panel:noBackground()

    -- Custom render for rounded background
    panel.prerender = function(self)
        local colors = ZombifyShared.getThemeColors(config.theme)
        self:drawRect(0, 0, self.width, self.height, colors.background.a, colors.background.r, colors.background.g, colors.background.b)
        self:drawRectBorder(0, 0, self.width, self.height, colors.border.a, colors.border.r, colors.border.g, colors.border.b)
    end

    -- Album art
    local artSize = math.min(80, h - 20)
    panel.albumArt = ISImage:new(10, 10, artSize, artSize, nil)
    panel.albumArt:initialise()
    panel.albumArt.scaled = true
    panel:addChild(panel.albumArt)

    -- Track info labels
    local labelX = 10 + artSize + 10
    local labelW = w - labelX - 10

    panel.trackLabel = ISLabel:new(labelX, 10, 22, "Track Name", 1, 1, 1, 1, UIFont.Medium, true)
    panel.trackLabel:initialise()
    panel.trackLabel.maxWidth = labelW
    panel:addChild(panel.trackLabel)

    panel.artistLabel = ISLabel:new(labelX, 34, 18, "Artist Name", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    panel.artistLabel:initialise()
    panel.artistLabel.maxWidth = labelW
    panel:addChild(panel.artistLabel)

    panel.albumLabel = ISLabel:new(labelX, 54, 18, "Album Name", 0.6, 0.6, 0.6, 1, UIFont.Small, true)
    panel.albumLabel:initialise()
    panel.albumLabel.maxWidth = labelW
    panel:addChild(panel.albumLabel)

    -- Progress bar
    local barY = 75
    local barX = labelX
    local barW = labelW

    panel.progressBg = ISPanel:new(barX, barY, barW, 8)
    panel.progressBg:initialise()
    panel.progressBg.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8}
    panel.progressBg:noBackground()
    panel.progressBg.prerender = function(self)
        local colors = ZombifyShared.getThemeColors(config.theme)
        self:drawRect(0, 0, self.width, self.height, colors.progressBg.a, colors.progressBg.r, colors.progressBg.g, colors.progressBg.b)
    end
    panel:addChild(panel.progressBg)

    panel.progressFg = ISPanel:new(barX, barY, 0, 8)
    panel.progressFg:initialise()
    panel.progressFg.backgroundColor = {r=0.2, g=0.7, b=0.3, a=1}
    panel.progressFg:noBackground()
    panel.progressFg.prerender = function(self)
        local colors = ZombifyShared.getThemeColors(config.theme)
        self:drawRect(0, 0, self.width, self.height, colors.progressFg.a, colors.progressFg.r, colors.progressFg.g, colors.progressFg.b)
    end
    panel:addChild(panel.progressFg)

    -- Time labels
    panel.currentTimeLabel = ISLabel:new(barX, barY + 10, 16, "0:00", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    panel.currentTimeLabel:initialise()
    panel:addChild(panel.currentTimeLabel)

    panel.totalTimeLabel = ISLabel:new(barX + barW - 40, barY + 10, 16, "4:00", 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    panel.totalTimeLabel:initialise()
    panel:addChild(panel.totalTimeLabel)

    -- Control buttons
    local btnY = h - 35
    local btnSize = 28

    panel.prevButton = ISButton:new(10, btnY, btnSize, btnSize, "", panel, ZombifyUI.onPrevClick)
    panel.prevButton:initialise()
    panel.prevButton.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.prevButton.borderColor = {r=0, g=0, b=0, a=0}
    panel.prevButton:setImage(getTexture("media/ui/ArrowLeft.png"))
    panel:addChild(panel.prevButton)

    panel.playPauseButton = ISButton:new(10 + btnSize + 5, btnY, btnSize, btnSize, "", panel, ZombifyUI.onPlayPauseClick)
    panel.playPauseButton:initialise()
    panel.playPauseButton.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.playPauseButton.borderColor = {r=0, g=0, b=0, a=0}
    panel.playPauseButton:setImage(getTexture("media/ui/Play.png"))
    panel:addChild(panel.playPauseButton)

    panel.nextButton = ISButton:new(10 + (btnSize + 5) * 2, btnY, btnSize, btnSize, "", panel, ZombifyUI.onNextClick)
    panel.nextButton:initialise()
    panel.nextButton.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.nextButton.borderColor = {r=0, g=0, b=0, a=0}
    panel.nextButton:setImage(getTexture("media/ui/ArrowRight.png"))
    panel:addChild(panel.nextButton)

    panel.volumeButton = ISButton:new(w - 10 - btnSize, btnY, btnSize, btnSize, "", panel, ZombifyUI.onVolumeClick)
    panel.volumeButton:initialise()
    panel.volumeButton.backgroundColor = {r=0, g=0, b=0, a=0}
    panel.volumeButton.borderColor = {r=0, g=0, b=0, a=0}
    panel.volumeButton:setImage(getTexture("media/ui/VolumeHigh.png"))
    panel:addChild(panel.volumeButton)

    panel.volumeSlider = ISSliderPanel:new(w - 10 - btnSize - 100, btnY + 2, 100, 24, panel, ZombifyUI.onVolumeChange)
    panel.volumeSlider:initialise()
    panel.volumeSlider:setValues(0.0, 1.0, 0.01, 0.5)
    panel:addChild(panel.volumeSlider)

    ZombifyUI.instance = panel

    -- Add to UI manager
    local player = getPlayer()
    if player and player:getUIManager() then
        player:getUIManager():AddUI(panel)
    end

    return panel
end

-- Update overlay with current music info
function ZombifyUI.updateOverlay()
    if not ZombifyUI.instance then return end

    local state = Zombify.State
    local config = Zombify.Config

    -- Update track info
    if state.currentTrack then
        ZombifyUI.instance.trackLabel:setName(state.currentTrack)
    end
    if state.currentArtist then
        ZombifyUI.instance.artistLabel:setName(state.currentArtist)
    end
    if state.currentAlbum then
        ZombifyUI.instance.albumLabel:setName(state.currentAlbum)
    end

    -- Update progress bar
    if state.duration > 0 then
        local progress = state.progress / state.duration
        local barW = ZombifyUI.instance.progressBg.width
        ZombifyUI.instance.progressFg:setWidth(math.floor(barW * progress))

        local currentMin = math.floor(state.progress / 60000)
        local currentSec = math.floor((state.progress % 60000) / 1000)
        local totalMin = math.floor(state.duration / 60000)
        local totalSec = math.floor((state.duration % 60000) / 1000)

        ZombifyUI.instance.currentTimeLabel:setName(string.format("%d:%02d", currentMin, currentSec))
        ZombifyUI.instance.totalTimeLabel:setName(string.format("%d:%02d", totalMin, totalSec))
    else
        ZombifyUI.instance.progressFg:setWidth(0)
        ZombifyUI.instance.currentTimeLabel:setName("0:00")
        ZombifyUI.instance.totalTimeLabel:setName("0:00")
    end

    -- Update play/pause button
    if state.isPlaying then
        ZombifyUI.instance.playPauseButton:setImage(getTexture("media/ui/Pause.png"))
    else
        ZombifyUI.instance.playPauseButton:setImage(getTexture("media/ui/Play.png"))
    end

    -- Update volume slider
    if ZombifyUI.instance.volumeSlider then
        ZombifyUI.instance.volumeSlider:setCurrentValue(state.volume or 0.5)
    end

    -- Update visibility based on config
    local shouldShow = config.enabled and config.modMode ~= "Disabled" and state.playerConnected

    if config.renderType == "WhenPlaying" and not state.isPlaying then
        shouldShow = false
    elseif config.renderType == "WhenPaused" and state.isPlaying then
        shouldShow = false
    end

    local player = getPlayer()
    if config.renderType == "InVehicle" and (not player or not player:getVehicle()) then
        shouldShow = false
    elseif config.renderType == "InMenu" and (not player or not player:getUIManager():isAnyUIOpen()) then
        shouldShow = false
    end

    ZombifyUI.instance:setVisible(shouldShow and state.isVisible)

    -- Update position
    local x, y, w, h = Zombify.getOverlayPosition()
    ZombifyUI.instance:setX(x)
    ZombifyUI.instance:setY(y)
    ZombifyUI.instance:setWidth(w)
    ZombifyUI.instance:setHeight(h)

    -- Update scale - recreate children if scale changed significantly
    -- For now just update positions
    local artSize = math.min(80, h - 20)
    ZombifyUI.instance.albumArt:setWidth(artSize)
    ZombifyUI.instance.albumArt:setHeight(artSize)

    local labelX = 10 + artSize + 10
    local labelW = w - labelX - 10
    ZombifyUI.instance.trackLabel:setX(labelX)
    ZombifyUI.instance.trackLabel.maxWidth = labelW
    ZombifyUI.instance.artistLabel:setX(labelX)
    ZombifyUI.instance.artistLabel.maxWidth = labelW
    ZombifyUI.instance.albumLabel:setX(labelX)
    ZombifyUI.instance.albumLabel.maxWidth = labelW

    local barX = labelX
    local barW = labelW
    ZombifyUI.instance.progressBg:setX(barX)
    ZombifyUI.instance.progressBg:setWidth(barW)
    ZombifyUI.instance.progressFg:setX(barX)
    ZombifyUI.instance.currentTimeLabel:setX(barX)
    ZombifyUI.instance.totalTimeLabel:setX(barX + barW - 40)

    local btnY = h - 35
    local btnSize = 28
    ZombifyUI.instance.prevButton:setX(10)
    ZombifyUI.instance.prevButton:setY(btnY)
    ZombifyUI.instance.playPauseButton:setX(10 + btnSize + 5)
    ZombifyUI.instance.playPauseButton:setY(btnY)
    ZombifyUI.instance.nextButton:setX(10 + (btnSize + 5) * 2)
    ZombifyUI.instance.nextButton:setY(btnY)
    ZombifyUI.instance.volumeButton:setX(w - 10 - btnSize)
    ZombifyUI.instance.volumeButton:setY(btnY)
    ZombifyUI.instance.volumeSlider:setX(w - 10 - btnSize - 100)
    ZombifyUI.instance.volumeSlider:setY(btnY + 2)

    -- Show/hide elements based on display mode
    if config.displayMode == "Compact" then
        ZombifyUI.instance.albumArt:setVisible(false)
        ZombifyUI.instance.albumLabel:setVisible(false)
    elseif config.displayMode == "Minimal" then
        ZombifyUI.instance.albumArt:setVisible(false)
        ZombifyUI.instance.albumLabel:setVisible(false)
        ZombifyUI.instance.artistLabel:setVisible(false)
        ZombifyUI.instance.progressBg:setVisible(false)
        ZombifyUI.instance.progressFg:setVisible(false)
        ZombifyUI.instance.currentTimeLabel:setVisible(false)
        ZombifyUI.instance.totalTimeLabel:setVisible(false)
    else
        ZombifyUI.instance.albumArt:setVisible(config.showAlbumArt)
        ZombifyUI.instance.albumLabel:setVisible(true)
        ZombifyUI.instance.artistLabel:setVisible(true)
        ZombifyUI.instance.progressBg:setVisible(config.showProgressBar)
        ZombifyUI.instance.progressFg:setVisible(config.showProgressBar)
        ZombifyUI.instance.currentTimeLabel:setVisible(config.showProgressBar)
        ZombifyUI.instance.totalTimeLabel:setVisible(config.showProgressBar)
    end

    ZombifyUI.instance.prevButton:setVisible(config.showControls)
    ZombifyUI.instance.playPauseButton:setVisible(config.showControls)
    ZombifyUI.instance.nextButton:setVisible(config.showControls)
    ZombifyUI.instance.volumeButton:setVisible(config.showControls)
    ZombifyUI.instance.volumeSlider:setVisible(config.showControls)
end

-- Button callbacks
function ZombifyUI.onPrevClick(button)
    Zombify.controlPrev()
end

function ZombifyUI.onPlayPauseClick(button)
    Zombify.controlPlayPause()
end

function ZombifyUI.onNextClick(button)
    Zombify.controlNext()
end

function ZombifyUI.onVolumeClick(button)
    -- Toggle mute
    if Zombify.State.volume > 0 then
        Zombify.State.lastVolume = Zombify.State.volume
        Zombify.State.volume = 0
    else
        Zombify.State.volume = Zombify.State.lastVolume or 0.5
    end
    ZombifyMusicPlayer.sendCommand("volume", {volume = Zombify.State.volume})
end

function ZombifyUI.onVolumeChange(slider, value)
    Zombify.State.volume = value
    ZombifyMusicPlayer.sendCommand("volume", {volume = value})
end

-- Show overlay
function ZombifyUI.show()
    if not ZombifyUI.instance then
        ZombifyUI.createOverlay()
    end
    ZombifyUI.instance:setVisible(true)
    Zombify.State.isVisible = true
end

-- Hide overlay
function ZombifyUI.hide()
    if ZombifyUI.instance then
        ZombifyUI.instance:setVisible(false)
    end
    Zombify.State.isVisible = false
end

-- Toggle overlay
function ZombifyUI.toggle()
    if Zombify.State.isVisible then
        ZombifyUI.hide()
    else
        ZombifyUI.show()
    end
end

-- Clean up
function ZombifyUI.cleanup()
    if ZombifyUI.instance then
        ZombifyUI.instance:removeFromUIManager()
        ZombifyUI.instance = nil
    end
end