local L = CombRotate.L

-- Adds mage to global table and one of the two rotation tables
function CombRotate:registerMage(mageName)

    -- Initialize mage 'object'
    local mage = {}
    mage.name = mageName
    mage.GUID = UnitGUID(mageName)
    mage.frame = nil
    mage.nextComb = false
    mage.lastCombTime = 0
    mage.lastFailTime = 0

    -- Add to global list
    table.insert(CombRotate.mageTable, mage)

    -- Add to rotation or backup group depending on rotation group size
    if (#CombRotate.rotationTables.rotation > 2) then
        table.insert(CombRotate.rotationTables.backup, mage)
    else
        table.insert(CombRotate.rotationTables.rotation, mage)
    end

    CombRotate:drawMageFrames()

    return mage
end

-- Removes a mage from all lists
function CombRotate:removeMage(deletedMage)

    -- Clear from global list
    for key, mage in pairs(CombRotate.mageTable) do
        if (mage.name == deletedMage.name) then
            CombRotate:hideMage(mage)
            table.remove(CombRotate.mageTable, key)
            break
        end
    end

    -- clear from rotation lists
    for key, mageTable in pairs(CombRotate.rotationTables) do
        for subkey, mage in pairs(mageTable) do
            if (mage.name == deletedMage.name) then
                table.remove(mageTable, subkey)
            end
        end
    end

    CombRotate:drawMageFrames()
end

-- Update the rotation list once a combustion has been applied.
-- The parameter is the mage that applied it
function CombRotate:rotate(lastMage, rotateWithoutCooldown)

    local lastMageRotationTable = CombRotate:getMageRotationTable(lastMage)

    lastMage.lastCombTime = GetTime()

    -- Do not trigger cooldown when rotation from a dead or disconnected status
    if (rotateWithoutCooldown ~= true) then
        CombRotate:startMageCooldown(lastMage)
    end

    local nextMage = nil

    if (lastMageRotationTable == CombRotate.rotationTables.rotation) then
        nextMage = CombRotate:getNextRotationMage(lastMage)

        if (nextMage ~= nil) then
            CombRotate:setNextComb(nextMage)
        end
    end
end

-- Handle miss or dispel resist scenario
function CombRotate:handleFailComb(mage, event)

    -- Do not process multiple SPELL_DISPEL_FAILED events or multiple fail broadcasts
    local duplicate = mage.lastFailTime >= GetTime() - CombRotate.constants.duplicateCombustionDelayThreshold
    if (duplicate) then
        return
    end

    CombRotate:printFail(mage, event)

    local playerName, realm = UnitName("player")
    local hasPlayerFailed = playerName == mage.name
    local nextMage = CombRotate:getHighlightedMage()
    local lastMageRotationTable = CombRotate:getMageRotationTable(mage)

    -- Could happen if the first event received is a miss/resist
    if (nextMage == nil) then
        nextMage = CombRotate:getNextRotationMage(mage)
    end

    mage.lastFailTime = GetTime()

    -- No backup, if player is next in rotation he will be warned to handle the fail
    if (
            lastMageRotationTable == CombRotate.rotationTables.rotation and
                    nextMage.name == playerName and
                    #CombRotate.rotationTables.backup < 1 and
                    CombRotate:isMageCombustionCooldownReady(nextMage)
    ) then
        CombRotate:throwCombAlert()
    end

    -- The player failed, sending fail message and backup alerts
    if (hasPlayerFailed) then
        CombRotate:alertBackup(CombRotate.db.profile.whisperFailMessage, nextMage, true)
    end

    -- Player is in backup group, display an alert when someone fails
    local playerRotationTable = CombRotate:getMageRotationTable(CombRotate:getMage(playerName))
    if (playerRotationTable == CombRotate.rotationTables.backup and not hasPlayerFailed) then
        CombRotate:throwCombAlert()
    end
end

-- Removes all nextComb flags and set it true for next caster
function CombRotate:setNextComb(nextMage)
    for key, mage in pairs(CombRotate.rotationTables.rotation) do
        if (mage.name == nextMage.name) then
            mage.nextComb = true

            if (nextMage.name == UnitName("player")) and CombRotate.db.profile.enableNextToCombSound then
                PlaySoundFile(CombRotate.constants.sounds.nextToComb)
            end
        else
            mage.nextComb = false
        end

        CombRotate:refreshMageFrame(mage)
    end
end

-- Check if the player is the next in position to comb
function CombRotate:isPlayerNextComb()

    if(not CombRotate:isMage("player")) then
        return false
    end

    local player = CombRotate:getMage(UnitGUID("player"))

    if (not player.nextComb) then

        local isRotationInitialized = false;
        local rotationTable = CombRotate.rotationTables.rotation

        -- checking if a mage is flagged nextComb
        for key, mage in pairs(rotationTable) do
            if (mage.nextComb) then
                isRotationInitialized = true;
                break
            end
        end

        -- First in rotation has to use combustion if not one is active
        if (not isRotationInitialized and CombRotate:getMageIndex(player, rotationTable) == 1) then
            return true
        end

    end

    return player.nextComb
end

-- Find and returns the next mage that will trigger combustion on last caster
function CombRotate:getNextRotationMage(lastMage)

    local rotationTable = CombRotate.rotationTables.rotation
    local nextMage
    local lastMageIndex = 1

    -- Finding last mage index in rotation
    for key, mage in pairs(rotationTable) do
        if (mage.name == lastMage.name) then
            lastMageIndex = key
            break
        end
    end

    -- Search from last mage index if not last on rotation
    if (lastMageIndex < #rotationTable) then
        for index = lastMageIndex + 1 , #rotationTable, 1 do
            local mage = rotationTable[index]
            if (CombRotate:isEligibleForNextComb(mage)) then
                nextMage = mage
                break
            end
        end
    end

    -- Restart search from first index
    if (nextMage == nil) then
        for index = 1 , lastMageIndex, 1 do
            local mage = rotationTable[index]
            if (CombRotate:isEligibleForNextComb(mage)) then
                nextMage = mage
                break
            end
        end
    end

    -- If no mage in the rotation match the alive/online/CD criteria
    -- Pick the mage with the lowest cooldown
    if (nextMage == nil and #rotationTable > 0) then
        local latestComb = GetTime() + 1
        for key, mage in pairs(rotationTable) do
            if (CombRotate:isMageAliveAndOnline(mage) and mage.lastCombTime < latestComb) then
                nextMage = mage
                latestComb = mage.lastCombTime
            end
        end
    end

    return nextMage
end

-- Init/Reset rotation status, next combustion is the first mage on the list
function CombRotate:resetRotation()

    CombRotate.lastRotationReset = GetTime()

    for key, mage in pairs(CombRotate.rotationTables.rotation) do
        mage.nextComb = false
        CombRotate:refreshMageFrame(mage)
    end
end

-- TEST FUNCTION - Manually rotate mages for test purpose
function CombRotate:testRotation()

    local mageToRotate = nil
    for key, mage in pairs(CombRotate.rotationTables.rotation) do
        if (mage.nextComb) then
            mageToRotate = mage
            break
        end
    end

    if (not mageToRotate) then
        mageToRotate = CombRotate.rotationTables.rotation[1]
    end

    CombRotate:sendSyncComb(mageToRotate, false, GetTime())
    CombRotate:rotate(mageToRotate)
end

-- Return our mage object from name or GUID
function CombRotate:getMage(searchTerm)

    if (searchTerm == nil) then
        return nil
    end

    for _, mage in pairs(CombRotate.mageTable) do
        if (mage.GUID == searchTerm or mage.name == searchTerm) then
            return mage
        end
    end

    return nil
end

-- Iterate over mage list and purge mages that aren't in the group anymore
function CombRotate:purgeMageList()

    local mageToRemove = {}

    for _, mage in pairs(CombRotate.mageTable) do
        if (not UnitInParty(mage.name)) then
            table.insert(mageToRemove, mage)
        end
    end

    for _, mage in pairs(mageToRemove) do
        CombRotate:unregisterUnitEvents(mage)
        CombRotate:removeMage(mage)
    end
end

-- Iterate over all raid members to find mages and update their status
function CombRotate:updateRaidStatus()

    if (CombRotate:isInPveRaid()) then

        local playerCount = GetNumGroupMembers()
        local complete = true

        for index = 1, playerCount, 1 do

            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(index)

            -- Players name might be nil at loading
            if (name ~= nil) then
                if(CombRotate:isMage(name)) then
                    local mage = CombRotate:getMage(UnitGUID(name))

                    if (mage == nil and not InCombatLockdown()) then
                        mage = CombRotate:registerMage(name)
                        CombRotate:registerUnitEvents(mage)
                    end

                    if (mage ~= nil) then
                        CombRotate:updateMageStatus(mage)
                    end
                end
            else
                complete = false
            end
        end

        CombRotate:updateDragAndDrop()

        if (not CombRotate.raidInitialized) then
            if (not CombRotate.db.profile.doNotShowWindowOnRaidJoin) then
                CombRotate:updateDisplay()
            end
            CombRotate:sendSyncOrderRequest()
            CombRotate.raidInitialized = true
        end

        -- If some player names are nil, retry
        if (not complete and not CombRotate.delayedUpdate) then
            CombRotate.delayedUpdate = true
            C_Timer.After(1, function()
                CombRotate.delayedUpdate = false
                CombRotate:updateRaidStatus()
            end)
        end
    else
        if(CombRotate.raidInitialized == true) then
            CombRotate:updateDisplay()
            CombRotate.raidInitialized = false
        end
    end

    CombRotate:purgeMageList()
    CombRotate:purgeAddonVersions()
end

-- Update mage status
function CombRotate:updateMageStatus(mage)

    -- Jump to the next mage if the current one is dead or offline
    if (mage.nextComb and (not CombRotate:isMageAliveAndOnline(mage))) then
        CombRotate:rotate(mage, true)
    end

    CombRotate:refreshMageFrame(mage)
end

-- Moves given mage to the given position in the given group (ROTATION or BACKUP)
function CombRotate:moveMage(mage, group, position)

    local originTable = CombRotate:getMageRotationTable(mage)
    local originIndex = CombRotate:getMageIndex(mage, originTable)

    local destinationTable = CombRotate.rotationTables.rotation
    local finalIndex = position

    if (group == 'BACKUP') then
        destinationTable = CombRotate.rotationTables.backup
        -- Remove nextComb flag when moved to backup
        mage.nextComb = false
    end

    -- Setting originalIndex
    local sameTableMove = originTable == destinationTable

    -- Defining finalIndex
    if (sameTableMove) then
        if (position > #destinationTable or position == 0) then
            if (#destinationTable > 0) then
                finalIndex = #destinationTable
            else
                finalIndex = 1
            end
        end
    else
        if (position > #destinationTable + 1 or position == 0) then
            if (#destinationTable > 0) then
                finalIndex = #destinationTable  + 1
            else
                finalIndex = 1
            end
        end
    end

    if (sameTableMove) then
        if (originIndex ~= finalIndex) then
            table.remove(originTable, originIndex)
            table.insert(originTable, finalIndex, mage)
        end
    else
        table.remove(originTable, originIndex)
        table.insert(destinationTable, finalIndex, mage)
    end

    CombRotate:drawMageFrames()
end

-- Find the table that contains given mage (rotation or backup)
function CombRotate:getMageRotationTable(mage)
    if (CombRotate:tableContains(CombRotate.rotationTables.rotation, mage)) then
        return CombRotate.rotationTables.rotation
    end
    if (CombRotate:tableContains(CombRotate.rotationTables.backup, mage)) then
        return CombRotate.rotationTables.backup
    end
end

-- Returns a mages' index in the given table
function CombRotate:getMageIndex(mage, table)
    local originIndex = 0

    for key, loopMage in pairs(table) do
        if (mage.name == loopMage.name) then
            originIndex = key
            break
        end
    end

    return originIndex
end

-- Builds simple rotation tables containing only mage names
function CombRotate:getSimpleRotationTables()

    local simpleTables = { rotation = {}, backup = {} }

    for key, rotationTable in pairs(CombRotate.rotationTables) do
        for _, mage in pairs(rotationTable) do
            table.insert(simpleTables[key], mage.GUID)
        end
    end

    return simpleTables
end

-- Apply a simple rotation configuration
function CombRotate:applyRotationConfiguration(rotationsTables)

    for key, rotationTable in pairs(rotationsTables) do

        local group = 'ROTATION'
        if (key == 'backup') then
            group = 'BACKUP'
        end

        for index, GUID in pairs(rotationTable) do
            local mage = CombRotate:getMage(GUID)
            if (mage) then
                CombRotate:moveMage(mage, group, index)
            end
        end
    end
end

-- Display an alert and play a sound when the player should immediately use combustion
function CombRotate:throwCombAlert()
    RaidNotice_AddMessage(RaidWarningFrame, CombRotate.db.profile.useCombNowMessage, ChatTypeInfo["RAID_WARNING"])

    if (CombRotate.db.profile.enableCombNowSound) then
        PlaySoundFile(CombRotate.constants.sounds.alarms[CombRotate.db.profile.combNowSound])
    end
end

-- Send a defined message to backup player or next rotation player if there's no backup
function CombRotate:alertBackup(message, nextMage, noComms)
    local playerName = UnitName('player')
    local player = CombRotate:getMage(playerName)

    -- Non mage have no reason to ask for backup
    if (not CombRotate:isMage('player')) then
        return
    end

    if (#CombRotate.rotationTables.backup < 1) then

        if (nextMage == nil) then
            nextMage = CombRotate:getNextRotationMage(player)
        end

        if (playerName ~= nextMage.name) then
            SendChatMessage(message, 'WHISPER', nil, nextMage.name)
            if (noComms ~= true) then
                CombRotate:sendBackupRequest(nextMage.name)
            end
        end
    else
        CombRotate:whisperBackup(message, noComms)
    end
end

-- Whisper provided message of fail message to all backup except player
function CombRotate:whisperBackup(message, noComms)

    if (message == nil) then
        message = CombRotate.db.profile.whisperFailMessage
    end

    for key, backupMage in pairs(CombRotate.rotationTables.backup) do
        if (backupMage.name ~= UnitName("player")) then
            SendChatMessage(message, 'WHISPER', nil, backupMage.name)

            if (noComms ~= true) then
                CombRotate:sendBackupRequest(backupMage.name)
            end
        end
    end
end

-- Returns the mage currently wearing the "next" flag
function CombRotate:getHighlightedMage()

    for key, mage in pairs(CombRotate.rotationTables.rotation) do
        if (mage.nextComb) then
            return mage
        end
    end

    return nil
end

function CombRotate:getCombSuccessMessage(targetName, raidIconFlags)

    local message = CombRotate.db.profile.announceBossSuccessMessage
    local mage = CombRotate:getHighlightedMage()
    message = string.format(message, CombRotate:formatPlayerName(mage.name))

    return message
end

function CombRotate:getCombFailMessage(isFireImmune, targetName, raidIconFlags)

    local message = ""
    if (isFireImmune) then
        message = CombRotate.db.profile.announceImmuneMessage
    else
        message = CombRotate.db.profile.unableToCombMessage
    end

    message = string.format(
            message,
            TranqRotate:getRaidTargetIcon(raidIconFlags) .. targetName
    )

    return message
end

function CombRotate:handleResetButton()
    CombRotate:updateRaidStatus()
    if (CombRotate:isPlayerAllowedToManageRotation()) then
        CombRotate:endEncounter()
    else
        CombRotate:printPrefixedMessage(L["RESET_UNAUTHORIZED"])
    end
end

-- Player left combat
function CombRotate:endEncounter()
    CombRotate:resetRotation()
    CombRotate:sendResetBroadcast()
end