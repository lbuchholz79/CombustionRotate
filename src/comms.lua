local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")

local L = CombRotate.L

-- Register comm prefix at initialization steps
function CombRotate:initComms()

    CombRotate.syncVersion = 0
    CombRotate.syncLastSender = ''

    AceComm:RegisterComm(CombRotate.constants.commsPrefix, CombRotate.OnCommReceived)
end

-- Handle message reception and
function CombRotate.OnCommReceived(prefix, data, channel, sender)

    if not UnitIsUnit('player', sender) then

        local success, message = AceSerializer:Deserialize(data)
        CombRotate:debug("receivedAddonMessage " .. message)

        if (success) then
            if (message.type == CombRotate.constants.commsTypes.combDone) then
                CombRotate:receiveSyncComb(prefix, message, channel, sender)
            elseif (message.type == CombRotate.constants.commsTypes.syncOrder) then
                CombRotate:receiveSyncOrder(prefix, message, channel, sender)
            elseif (message.type == CombRotate.constants.commsTypes.syncRequest) then
                CombRotate:receiveSyncRequest(prefix, message, channel, sender)
            elseif (message.type == CombRotate.constants.commsTypes.backupRequest) then
                CombRotate:receiveBackupRequest(prefix, message, channel, sender)
            elseif (message.type == CombRotate.constants.commsTypes.reset) then
                CombRotate:receiveResetRequest(prefix, message, channel, sender)
            end
        end
    end
end

-- Checks if a given version from a given sender should be applied
function CombRotate:isVersionEligible(version, sender)
    return version > CombRotate.syncVersion or (version == CombRotate.syncVersion and sender < CombRotate.syncLastSender)
end

-----------------------------------------------------------------------------------------------------------------------
-- Messaging functions
-----------------------------------------------------------------------------------------------------------------------

-- Proxy to send raid addon message
function CombRotate:sendRaidAddonMessage(message)
    CombRotate:sendAddonMessage(message, CombRotate.constants.commsChannel)
end

-- Proxy to send whisper addon message
function CombRotate:sendWhisperAddonMessage(message, name)
    CombRotate:sendAddonMessage(message, 'WHISPER', name)
end

-- Broadcast a given message to the commsChannel with the commsPrefix
function CombRotate:sendAddonMessage(message, channel, name)
    CombRotate:debug("sendAddonMessage " .. message)
    AceComm:SendCommMessage(
        CombRotate.constants.commsPrefix,
        AceSerializer:Serialize(message),
        channel,
        name
    )
end

-----------------------------------------------------------------------------------------------------------------------
-- OUTPUT
-----------------------------------------------------------------------------------------------------------------------

-- Broadcast a combustion event
function CombRotate:sendSyncComb(mage, fail, timestamp, failEvent)
    local message = {
        ['type'] = CombRotate.constants.commsTypes.combDone,
        ['timestamp'] = timestamp,
        ['player'] = mage.GUID,
        ['fail'] = fail,
        ['failEvent'] = failEvent,
    }

    CombRotate:sendRaidAddonMessage(message)
end

-- Broadcast current rotation configuration
function CombRotate:sendSyncOrder(whisper, name)

    CombRotate.syncVersion = CombRotate.syncVersion + 1
    CombRotate.syncLastSender = UnitName("player")

    local message = {
        ['type'] = CombRotate.constants.commsTypes.syncOrder,
        ['version'] = CombRotate.syncVersion,
        ['rotation'] = CombRotate:getSimpleRotationTables(),
        ['addonVersion'] = CombRotate.version,
    }

    local nextMage = CombRotate:getHighlightedMage()
    if (nil ~= nextMage) then
        message.nextMage = nextMage.GUID
    end

    if (whisper) then
        CombRotate:sendWhisperAddonMessage(message, name)
    else
        CombRotate:sendRaidAddonMessage(message, name)
    end
end

-- Broadcast a request for the current rotation configuration
function CombRotate:sendSyncOrderRequest()

    local message = {
        ['type'] = CombRotate.constants.commsTypes.syncRequest,
        ['addonVersion'] = CombRotate.version,
    }

    CombRotate:sendRaidAddonMessage(message)
end

-- Broadcast a request for the current rotation configuration
function CombRotate:sendBackupRequest(name)

    CombRotate:printPrefixedMessage(string.format(L['COMMS_SENT_BACKUP_REQUEST'], CombRotate:formatPlayerName(name)))

    local message = {
        ['type'] = CombRotate.constants.commsTypes.backupRequest,
    }

    CombRotate:sendWhisperAddonMessage(message, name)
end

-- Broadcast a reset of the rotation to other players
function CombRotate:sendResetBroadcast()

    local message = {
        ['type'] = CombRotate.constants.commsTypes.reset,
    }

    CombRotate:sendRaidAddonMessage(message)
end

-----------------------------------------------------------------------------------------------------------------------
-- INPUT
-----------------------------------------------------------------------------------------------------------------------

-- Combustion event received
function CombRotate:receiveSyncComb(prefix, message, channel, sender)

    local mage = CombRotate:getMage(message.player)

    if (mage == nil) then
        return
    end

    if (not message.fail) then
        local notDuplicate = mage.lastCombTime <  GetTime() - CombRotate.constants.duplicateCombustionDelayThreshold
        if (notDuplicate) then
            CombRotate:rotate(mage)
        end
    end
end

-- Rotation configuration received
function CombRotate:receiveSyncOrder(prefix, message, channel, sender)

    CombRotate:updateRaidStatus()

    if (CombRotate:isVersionEligible(message.version, sender)) then
        CombRotate.syncVersion = (message.version)
        CombRotate.syncLastSender = sender

        CombRotate:printPrefixedMessage(string.format(L['COMMS_RECEIVED_NEW_ROTATION'], CombRotate:formatPlayerName(sender)))

        CombRotate:applyRotationConfiguration(message.rotation)

        local nextMage = CombRotate:getMage(message.nextMage)
        if (nil ~= nextMage) then
            CombRotate:setNextComb(nextMage)
        end
    end

    CombRotate:updatePlayerAddonVersion(sender, message.addonVersion)
end

-- Request to send current roration configuration received
function CombRotate:receiveSyncRequest(prefix, message, channel, sender)
    CombRotate:updatePlayerAddonVersion(sender, message.addonVersion)
    CombRotate:sendSyncOrder(true, sender)
end

-- Received a backup request
function CombRotate:receiveBackupRequest(prefix, message, channel, sender)
    CombRotate:printPrefixedMessage(string.format(L['COMMS_RECEIVED_BACKUP_REQUEST'], CombRotate:formatPlayerName(sender)))

    CombRotate:throwCombAlert()
end

-- Received a rotation reset request
function CombRotate:receiveResetRequest(prefix, message, channel, sender)

    if (not CombRotate:isUnitAllowedToManageRotation(sender)) then
        return
    end

    if (CombRotate.lastRotationReset < GetTime() - 2) then
        CombRotate:printPrefixedMessage(string.format(L['COMMS_RECEIVED_RESET_BROADCAST'], CombRotate:formatPlayerName(sender)))

        CombRotate:resetRotation()
    end
end
