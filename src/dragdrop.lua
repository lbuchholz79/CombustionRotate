-- Enable drag & drop for all mage frames
function CombRotate:toggleListSorting(allowSorting)
    for key, mage in pairs(CombRotate.mageTable) do
        CombRotate:toggleMageFrameDragging(mage, allowSorting)
    end
end

-- Enable or disable drag & drop for the mage frame
function CombRotate:toggleMageFrameDragging(mage, allowSorting)
    mage.frame:EnableMouse(allowSorting)
    mage.frame:SetMovable(allowSorting)
end

-- configure mage frame drag behavior
function CombRotate:configureMageFrameDrag(mage)

    mage.frame:RegisterForDrag("LeftButton")
    mage.frame:SetClampedToScreen(true)

    mage.frame.blindIconFrame:RegisterForDrag("LeftButton")
    mage.frame.blindIconFrame:SetClampedToScreen(true)

    mage.frame:SetScript(
        "OnDragStart",
        function()
            mage.frame:StartMoving()
            mage.frame:SetFrameStrata("HIGH")

            mage.frame:SetScript(
                "OnUpdate",
                function ()
                    CombRotate:setDropHintPosition(mage.frame)
                end
            )

            CombRotate.mainFrame.dropHintFrame:Show()
            CombRotate.mainFrame.backupFrame:Show()
        end
    )

    mage.frame:SetScript(
        "OnDragStop",
        function()
            mage.frame:StopMovingOrSizing()
            mage.frame:SetFrameStrata(CombRotate.mainFrame:GetFrameStrata())
            CombRotate.mainFrame.dropHintFrame:Hide()

            -- Removes the OnUpdate event used for drag & drop
            mage.frame:SetScript("OnUpdate", nil)

            if (#CombRotate.rotationTables.backup < 1) then
                CombRotate.mainFrame.backupFrame:Hide()
            end

            local group, position = CombRotate:getDropPosition(mage.frame)
            CombRotate:handleDrop(mage, group, position)
            CombRotate:sendSyncOrder(false)
        end
    )
end

-- returns the difference between the top of the rotation frame and the dragged mage frame
function CombRotate:getDragFrameHeight(mageFrame)
    return math.abs(mageFrame:GetTop() - CombRotate.mainFrame.rotationFrame:GetTop())
end

-- create and initialize the drop hint frame
function CombRotate:createDropHintFrame()

    local hintFrame = CreateFrame("Frame", nil, CombRotate.mainFrame.rotationFrame)

    hintFrame:SetPoint('TOP', CombRotate.mainFrame.rotationFrame, 'TOP', 0, 0)
    hintFrame:SetHeight(CombRotate.constants.mageFrameHeight)
    hintFrame:SetWidth(CombRotate.constants.mainFrameWidth - 10)

    hintFrame.texture = hintFrame:CreateTexture(nil, "BACKGROUND")
    hintFrame.texture:SetColorTexture(CombRotate.colors.white:GetRGB())
    hintFrame.texture:SetAlpha(0.7)
    hintFrame.texture:SetPoint('LEFT')
    hintFrame.texture:SetPoint('RIGHT')
    hintFrame.texture:SetHeight(2)

    hintFrame:Hide()

    CombRotate.mainFrame.dropHintFrame = hintFrame
end

-- Set the drop hint frame position to match dragged frame position
function CombRotate:setDropHintPosition(mageFrame)

    local mageFrameHeight = CombRotate.constants.mageFrameHeight
    local mageFrameSpacing = CombRotate.constants.mageFrameSpacing
    local hintPosition = 0

    local group, position = CombRotate:getDropPosition(mageFrame)

    if (group == 'ROTATION') then
        if (position == 0) then
            hintPosition = -2
        else
            hintPosition = (position) * (mageFrameHeight + mageFrameSpacing) - mageFrameSpacing / 2;
        end
    else
        hintPosition = CombRotate.mainFrame.rotationFrame:GetHeight()

        if (position == 0) then
            hintPosition = hintPosition - 2
        else
            hintPosition = hintPosition + (position) * (mageFrameHeight + mageFrameSpacing) - mageFrameSpacing / 2;
        end
    end

    CombRotate.mainFrame.dropHintFrame:SetPoint('TOP', 0 , -hintPosition)
end

-- Compute drop group and position from ruler height
function CombRotate:getDropPosition(mageFrame)

    local height = CombRotate:getDragFrameHeight(mageFrame)
    local group = 'ROTATION'
    local position = 0

    local mageFrameHeight = CombRotate.constants.mageFrameHeight
    local mageFrameSpacing = CombRotate.constants.mageFrameSpacing

    -- Dragged frame is above rotation frames
    if (mageFrame:GetTop() > CombRotate.mainFrame.rotationFrame:GetTop()) then
        height = 0
    end

    position = floor(height / (mageFrameHeight + mageFrameSpacing))

    -- Dragged frame is bellow rotation frame
    if (height > CombRotate.mainFrame.rotationFrame:GetHeight()) then

        group = 'BACKUP'

        -- Removing rotation frame size from calculation, using it's height as base hintPosition offset
        height = height - CombRotate.mainFrame.rotationFrame:GetHeight()

        if (height > CombRotate.mainFrame.backupFrame:GetHeight()) then
            -- Dragged frame is bellow backup frame
            position = #CombRotate.rotationTables.backup
        else
            position = floor(height / (mageFrameHeight + mageFrameSpacing))
        end
    end

    return group, position
end

-- Compute the table final position from the drop position
function CombRotate:handleDrop(mage, group, position)

    local originTable = CombRotate:getMageRotationTable(mage)
    local originIndex = CombRotate:getMageIndex(mage, originTable)

    local destinationTable = CombRotate.rotationTables.rotation
    local finalPosition = 1

    if (group == "BACKUP") then
        destinationTable = CombRotate.rotationTables.backup
    end

    if (destinationTable == originTable) then

        if (position == originIndex or position == originIndex - 1 ) then
            finalPosition = originIndex
        else
            if (position > originIndex) then
                finalPosition = position
            else
                finalPosition = position + 1
            end
        end

    else
        finalPosition = position + 1
    end

    CombRotate:moveMage(mage, group, finalPosition)
end

-- Update drag and drop status to match player status
function CombRotate:updateDragAndDrop()
    CombRotate:toggleListSorting(CombRotate:isPlayerAllowedToManageRotation())
end
