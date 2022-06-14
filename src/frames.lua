local L = CombRotate.L

-- Create main window
function CombRotate:createMainFrame()
    CombRotate.mainFrame = CreateFrame("Frame", 'mainFrame', UIParent)
    CombRotate.mainFrame:SetWidth(CombRotate.constants.mainFrameWidth)
    CombRotate.mainFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight * 2 + CombRotate.constants.titleBarHeight)
    CombRotate.mainFrame:Show()

    CombRotate.mainFrame:RegisterForDrag("LeftButton")
    CombRotate.mainFrame:SetClampedToScreen(true)
    CombRotate.mainFrame:SetScript("OnDragStart", function() CombRotate.mainFrame:StartMoving() end)

    CombRotate.mainFrame:SetScript(
        "OnDragStop",
        function()
            CombRotate.mainFrame:StopMovingOrSizing()

            CombRotate.db.profile.point = 'TOPLEFT'
            CombRotate.db.profile.y = CombRotate.mainFrame:GetTop()
            CombRotate.db.profile.x = CombRotate.mainFrame:GetLeft()
        end
    )
end

function CombRotate:resetMainWindowPosition()
    CombRotate.db.profile.point = nil
    CombRotate.db.profile.y = nil
    CombRotate.db.profile.x = nil

    CombRotate.mainFrame:ClearAllPoints()
    CombRotate.mainFrame:SetPoint('CENTER')
end

-- Create Title frame
function CombRotate:createTitleFrame()
    CombRotate.mainFrame.titleFrame = CreateFrame("Frame", 'rotationFrame', CombRotate.mainFrame)
    CombRotate.mainFrame.titleFrame:SetPoint('TOPLEFT')
    CombRotate.mainFrame.titleFrame:SetPoint('TOPRIGHT')
    CombRotate.mainFrame.titleFrame:SetHeight(CombRotate.constants.titleBarHeight)

    CombRotate.mainFrame.titleFrame.texture = CombRotate.mainFrame.titleFrame:CreateTexture(nil, "BACKGROUND")
    CombRotate.mainFrame.titleFrame.texture:SetColorTexture(CombRotate.colors.headerBg:GetRGB())
    CombRotate.mainFrame.titleFrame.texture:SetAllPoints()

    CombRotate.mainFrame.titleFrame.text = CombRotate.mainFrame.titleFrame:CreateFontString(nil, "ARTWORK")
    CombRotate.mainFrame.titleFrame.text:SetFont("Fonts\\ARIALN.ttf", 12)
    CombRotate.mainFrame.titleFrame.text:SetShadowColor(CombRotate.colors.shadow:GetRGBA())
    CombRotate.mainFrame.titleFrame.text:SetShadowOffset(1,-1)
    CombRotate.mainFrame.titleFrame.text:SetPoint("LEFT",5,0)
    CombRotate.mainFrame.titleFrame.text:SetText('CombustionRotate')
    CombRotate.mainFrame.titleFrame.text:SetTextColor(CombRotate.colors.header:GetRGBA())
end

-- Create title bar buttons
function CombRotate:createButtons()

    local buttons = {
        {
            texture = 'Interface/Buttons/UI-Panel-MinimizeButton-Up',
            callback = CombRotate.toggleDisplay,
            textCoord = {0.18, 0.8, 0.2, 0.8},
            tooltip = L['BUTTON_CLOSE'],
        },
        {
            texture = 'Interface/GossipFrame/BinderGossipIcon',
            callback = CombRotate.openSettings,
            tooltip = L['BUTTON_SETTINGS'],
        },
        {
            texture = 'Interface/Buttons/UI-RefreshButton',
            callback = CombRotate.handleResetButton,
            tooltip = L['BUTTON_RESET_ROTATION'],
        },
        {
            texture = 'Interface/Buttons/UI-GuildButton-MOTD-Up',
            callback = CombRotate.printRotationSetup,
            tooltip = L['BUTTON_PRINT_ROTATION'],
        },
    }

    local position = 5

    for key, button in pairs(buttons) do
        CombRotate:createButton(position, button.texture, button.callback, button.textCoord, button.tooltip)
        position = position + 13
    end
end

-- Create a single button in the title bar
function CombRotate:createButton(position, texture, callback, textCoord, tooltip)

    local button = CreateFrame("Button", nil, CombRotate.mainFrame.titleFrame)
    button:SetPoint('RIGHT', -position, 0)
    button:SetWidth(10)
    button:SetHeight(10)

    local normal = button:CreateTexture()
    normal:SetTexture(texture)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)

    local highlight = button:CreateTexture()
    highlight:SetTexture(texture)
    highlight:SetAllPoints()
    button:SetHighlightTexture(highlight)

    if (textCoord) then
        normal:SetTexCoord(unpack(textCoord))
        highlight:SetTexCoord(unpack(textCoord))
    end

    button:SetScript("OnClick", callback)

    if tooltip then
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, tooltip)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

-- Create rotation frame
function CombRotate:createRotationFrame()
    CombRotate.mainFrame.rotationFrame = CreateFrame("Frame", 'rotationFrame', CombRotate.mainFrame)
    CombRotate.mainFrame.rotationFrame:SetPoint('LEFT')
    CombRotate.mainFrame.rotationFrame:SetPoint('RIGHT')
    CombRotate.mainFrame.rotationFrame:SetPoint('TOP', 0, -CombRotate.constants.titleBarHeight)
    CombRotate.mainFrame.rotationFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight)

    CombRotate.mainFrame.rotationFrame.texture = CombRotate.mainFrame.rotationFrame:CreateTexture(nil, "BACKGROUND")
    CombRotate.mainFrame.rotationFrame.texture:SetColorTexture(0,0,0,0.5)
    CombRotate.mainFrame.rotationFrame.texture:SetAllPoints()
end

-- Create backup frame
function CombRotate:createBackupFrame()
    -- Backup frame
    CombRotate.mainFrame.backupFrame = CreateFrame("Frame", 'backupFrame', CombRotate.mainFrame)
    CombRotate.mainFrame.backupFrame:SetPoint('TOPLEFT', CombRotate.mainFrame.rotationFrame, 'BOTTOMLEFT', 0, 0)
    CombRotate.mainFrame.backupFrame:SetPoint('TOPRIGHT', CombRotate.mainFrame.rotationFrame, 'BOTTOMRIGHT', 0, 0)
    CombRotate.mainFrame.backupFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight)

    -- Set Texture
    CombRotate.mainFrame.backupFrame.texture = CombRotate.mainFrame.backupFrame:CreateTexture(nil, "BACKGROUND")
    CombRotate.mainFrame.backupFrame.texture:SetColorTexture(0,0,0,0.5)
    CombRotate.mainFrame.backupFrame.texture:SetAllPoints()

    -- Visual separator
    CombRotate.mainFrame.backupFrame.texture = CombRotate.mainFrame.backupFrame:CreateTexture(nil, "BACKGROUND")
    CombRotate.mainFrame.backupFrame.texture:SetColorTexture(0.8,0.8,0.8,0.8)
    CombRotate.mainFrame.backupFrame.texture:SetHeight(1)
    CombRotate.mainFrame.backupFrame.texture:SetWidth(60)
    CombRotate.mainFrame.backupFrame.texture:SetPoint('TOP')
end

-- Create single mage frame
function CombRotate:createMageFrame(mage, parentFrame)
    mage.frame = CreateFrame("Frame", nil, parentFrame)
    mage.frame:SetHeight(CombRotate.constants.mageFrameHeight)

    -- Set Texture
    mage.frame.texture = mage.frame:CreateTexture(nil, "ARTWORK")
    mage.frame.texture:SetTexture("Interface\\AddOns\\CombustionRotate\\textures\\steel.tga")
    mage.frame.texture:SetAllPoints()

    -- Set Text
    mage.frame.text = mage.frame:CreateFontString(nil, "ARTWORK")
    mage.frame.text:SetFont(CombRotate:getPlayerNameFont(), 12)
    mage.frame.text:SetPoint("LEFT",5,0)
    mage.frame.text:SetText(CombRotate:formatPlayerName(mage.name))

    CombRotate:createCooldownFrame(mage)
    CombRotate:createBlindIconFrame(mage)
    CombRotate:configureMageFrameDrag(mage)

    CombRotate:toggleMageFrameDragging(mage, CombRotate:isPlayerAllowedToManageRotation())
end

-- Create the cooldown frame
function CombRotate:createCooldownFrame(mage)

    -- Frame
    mage.frame.cooldownFrame = CreateFrame("Frame", nil, mage.frame)
    mage.frame.cooldownFrame:SetPoint('LEFT', 5, 0)
    mage.frame.cooldownFrame:SetPoint('RIGHT', -5, 0)
    mage.frame.cooldownFrame:SetPoint('TOP', 0, -17)
    mage.frame.cooldownFrame:SetHeight(3)

    -- background
    mage.frame.cooldownFrame.background = mage.frame.cooldownFrame:CreateTexture(nil, "ARTWORK")
    mage.frame.cooldownFrame.background:SetColorTexture(0,0,0,1)
    mage.frame.cooldownFrame.background:SetAllPoints()

    local statusBar = CreateFrame("StatusBar", nil, mage.frame.cooldownFrame)
    statusBar:SetAllPoints()
    statusBar:SetMinMaxValues(0,1)

    local statusBarTexture = statusBar:CreateTexture(nil, "OVERLAY");
    statusBarTexture:SetColorTexture(1, 0, 0);
    statusBar:SetStatusBarTexture(statusBarTexture);

    mage.frame.cooldownFrame.statusBar = statusBar

    mage.frame.cooldownFrame:SetScript(
        "OnUpdate",
        function(self, elapsed)
            self.statusBar:SetValue(GetTime())

            if (self.statusBar.expirationTime < GetTime()) then
                self:Hide()
            end
        end
    )

    mage.frame.cooldownFrame:Hide()
end

-- Create the blind icon frame
function CombRotate:createBlindIconFrame(mage)

    -- Frame
    mage.frame.blindIconFrame = CreateFrame("Frame", nil, mage.frame)
    mage.frame.blindIconFrame:SetPoint('RIGHT', -5, 0)
    mage.frame.blindIconFrame:SetPoint('CENTER', 0, 0)
    mage.frame.blindIconFrame:SetWidth(16)
    mage.frame.blindIconFrame:SetHeight(16)

    -- Set Texture
    mage.frame.blindIconFrame.texture = mage.frame.blindIconFrame:CreateTexture(nil, "ARTWORK")
    mage.frame.blindIconFrame.texture:SetTexture("Interface\\AddOns\\CombustionRotate\\textures\\blind.tga")
    mage.frame.blindIconFrame.texture:SetAllPoints()
    mage.frame.blindIconFrame.texture:SetTexCoord(0.15, 0.85, 0.15, 0.85);

    -- Tooltip
    mage.frame.blindIconFrame:SetScript("OnEnter", CombRotate.onBlindIconEnter)
    mage.frame.blindIconFrame:SetScript("OnLeave", CombRotate.onBlindIconLeave)

    -- Drag & drop handlers
    mage.frame.blindIconFrame:SetScript("OnDragStart", function(self, ...)
        ExecuteFrameScript(self:GetParent(), "OnDragStart", ...);
    end)
    mage.frame.blindIconFrame:SetScript("OnDragStop", function(self, ...)
        ExecuteFrameScript(self:GetParent(), "OnDragStop", ...);
    end)

    mage.frame.blindIconFrame:Hide()
end

-- Blind icon tooltip show
function CombRotate:onBlindIconEnter()
    if (CombRotate.db.profile.showBlindIconTooltip) then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetText(L["TOOLTIP_PLAYER_WITHOUT_ADDON"])
        GameTooltip:AddLine(L["TOOLTIP_MAY_RUN_OUDATED_VERSION"])
        GameTooltip:AddLine(L["TOOLTIP_DISABLE_SETTINGS"])
        GameTooltip:Show()
    end
end

-- Blind icon tooltip hide
function CombRotate:onBlindIconLeave(self, motion)
    GameTooltip:Hide()
end
