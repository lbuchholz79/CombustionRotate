local L = CombRotate.L

-- Initialize GUI frames. Shouldn't be called more than once
function CombRotate:initGui()

    CombRotate:createMainFrame()
    CombRotate:createTitleFrame()
    CombRotate:createButtons()
    CombRotate:createRotationFrame()
    CombRotate:createBackupFrame()

    CombRotate:drawMageFrames()
    CombRotate:createDropHintFrame()

    CombRotate:updateDisplay()
end

-- Show/Hide main window based on user settings
function CombRotate:updateDisplay()

    if (not CombRotate.db.profile.doNotShowWindowOnRaidJoin and CombRotate:isInPveRaid()) then
        CombRotate.mainFrame:Show()
    else
        if (CombRotate.db.profile.hideNotInRaid) then
            CombRotate.mainFrame:Hide()
        end
    end
end

-- render / re-render mage frames to reflect table changes.
function CombRotate:drawMageFrames()

    -- Different height to reduce spacing between both groups
    CombRotate.mainFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight + CombRotate.constants.titleBarHeight)
    CombRotate.mainFrame.rotationFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight)

    CombRotate:drawList(CombRotate.rotationTables.rotation, CombRotate.mainFrame.rotationFrame)

    if (#CombRotate.rotationTables.backup > 0) then
        CombRotate.mainFrame:SetHeight(CombRotate.mainFrame:GetHeight() + CombRotate.constants.rotationFramesBaseHeight)
    end

    CombRotate.mainFrame.backupFrame:SetHeight(CombRotate.constants.rotationFramesBaseHeight)
    CombRotate:drawList(CombRotate.rotationTables.backup, CombRotate.mainFrame.backupFrame)

end

-- Handle the render of a single mage frames group
function CombRotate:drawList(mageList, parentFrame)

    local index = 1
    local mageFrameHeight = CombRotate.constants.mageFrameHeight
    local mageFrameSpacing = CombRotate.constants.mageFrameSpacing

    if (#mageList < 1 and parentFrame == CombRotate.mainFrame.backupFrame) then
        parentFrame:Hide()
    else
        parentFrame:Show()
    end

    for key, mage in pairs(mageList) do

        -- Using existing frame if possible
        if (mage.frame == nil) then
            CombRotate:createMageFrame(mage, parentFrame)
        else
            mage.frame:SetParent(parentFrame)
            mage.frame.text:SetText(CombRotate:formatPlayerName(mage.name))
        end

        mage.frame:ClearAllPoints()
        mage.frame:SetPoint('LEFT', 10, 0)
        mage.frame:SetPoint('RIGHT', -10, 0)

        -- Setting top margin
        local marginTop = 10 + (index - 1) * (mageFrameHeight + mageFrameSpacing)
        mage.frame:SetPoint('TOP', parentFrame, 'TOP', 0, -marginTop)

        -- Handling parent windows height increase
        if (index == 1) then
            parentFrame:SetHeight(parentFrame:GetHeight() + mageFrameHeight)
            CombRotate.mainFrame:SetHeight(CombRotate.mainFrame:GetHeight() + mageFrameHeight)
        else
            parentFrame:SetHeight(parentFrame:GetHeight() + mageFrameHeight + mageFrameSpacing)
            CombRotate.mainFrame:SetHeight(CombRotate.mainFrame:GetHeight() + mageFrameHeight + mageFrameSpacing)
        end

        -- SetColor
        CombRotate:setMageFrameColor(mage)
        -- Update blind version icon
        CombRotate:updateBlindIcon(mage)

        mage.frame:Show()
        mage.frame.mage = mage

        index = index + 1
    end
end

-- Hide the mage frame
function CombRotate:hideMage(mage)
    if (mage.frame ~= nil) then
        mage.frame:Hide()
    end
end

-- Refresh a single mage frame
function CombRotate:refreshMageFrame(mage)
    CombRotate:setMageFrameColor(mage)
    CombRotate:updateBlindIcon(mage)
end

-- Set the mage frame color regarding it's status
function CombRotate:setMageFrameColor(mage)

    local color = CombRotate.colors.blue

    if (not CombRotate:isMageOnline(mage)) then
        color = CombRotate.colors.gray
    elseif (not CombRotate:isMageAlive(mage)) then
        color = CombRotate.colors.red
    elseif (mage.nextComb) then
        color = CombRotate.colors.purple
    end

    mage.frame.texture:SetVertexColor(color:GetRGB())
end

-- Toggle blind icon display based on addonVersion
function CombRotate:updateBlindIcon(mage)
    if (
        not CombRotate.db.profile.showIconOnMageWithoutCombRotate or
        CombRotate.addonVersions[mage.name] ~= nil or
        mage.name == UnitName('player') or
        not CombRotate:isMageOnline(mage)
    ) then
        mage.frame.blindIconFrame:Hide()
    else
        mage.frame.blindIconFrame:Show()
    end
end

-- Refresh all blind icons
function CombRotate:refreshBlindIcons()
    for _, mage in pairs(CombRotate.mageTable) do
        CombRotate:updateBlindIcon(mage)
    end
end

-- Starts the combustion cooldown progress
function CombRotate:startMageCooldown(mage)
    mage.frame.cooldownFrame.statusBar:SetMinMaxValues(GetTime(), GetTime() + 20)
    mage.frame.cooldownFrame.statusBar.expirationTime = GetTime() + 20
    mage.frame.cooldownFrame:Show()
end

-- Lock/Unlock the mainFrame position
function CombRotate:lock(lock)
    CombRotate.db.profile.lock = lock
    CombRotate:applySettings()

    if (lock) then
        CombRotate:printMessage(L['WINDOW_LOCKED'])
    else
        CombRotate:printMessage(L['WINDOW_UNLOCKED'])
    end
end
