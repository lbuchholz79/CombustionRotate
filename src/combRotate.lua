CombRotate = select(2, ...)

local L = CombRotate.L

CombRotate.version = GetAddOnMetadata(..., "Version")

-- Initialize addon - Shouldn't be call more than once
function CombRotate:init()

    CombRotate:LoadDefaults()

    CombRotate.db = LibStub:GetLibrary("AceDB-3.0"):New("CombRotateDb", self.defaults, true)
    CombRotate.db.RegisterCallback(self, "OnProfileChanged", "ProfilesChanged")
    CombRotate.db.RegisterCallback(self, "OnProfileCopied", "ProfilesChanged")
    CombRotate.db.RegisterCallback(self, "OnProfileReset", "ProfilesChanged")

    CombRotate:CreateConfig()
    CombRotate:migrateProfile()

    CombRotate.mageTable = {}
    CombRotate.addonVersions = {}
    CombRotate.rotationTables = { rotation = {}, backup = {} }

    CombRotate.raidInitialized = false
    CombRotate.testMode = false
    CombRotate.frenzy = false
    CombRotate.lastRotationReset = 0

    CombRotate:initGui()
    CombRotate:updateRaidStatus()
    CombRotate:applySettings()
    CombRotate:updateDisplay()
    CombRotate:updateDragAndDrop()

    CombRotate:initComms()

    CombRotate:printMessage(L['LOADED_MESSAGE'])
end

-- Apply setting on profile change
function CombRotate:ProfilesChanged()
    self.db:RegisterDefaults(self.defaults)
    self:applySettings()
end

-- Apply settings
function CombRotate:applySettings()

    CombRotate.mainFrame:ClearAllPoints()

    local config = CombRotate.db.profile
    if config.point then
        CombRotate.mainFrame:SetPoint(config.point, UIParent, 'BOTTOMLEFT', config.x, config.y)
    else
        CombRotate.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    CombRotate.mainFrame:EnableMouse(not CombRotate.db.profile.lock)
    CombRotate.mainFrame:SetMovable(not CombRotate.db.profile.lock)
end

-- Print wrapper, just in case
function CombRotate:printMessage(msg)
    print(msg)
end

-- Print message with colored prefix
function CombRotate:printPrefixedMessage(msg)
    CombRotate:printMessage(CombRotate:colorText(CombRotate.constants.printPrefix) .. msg)
end

-- Print message with colored prefix
function CombRotate:debug(...)
    print("CombRotate", "DEBUG", ...)
end

-- Send a combustion announce message to a given channel
function CombRotate:sendAnnounceMessage(chatMessage)
    if CombRotate.db.profile.enableAnnounces then
        -- Prints instead to avoid lua error in open world with say and yell
        if (
            not IsInInstance() and
            (CombRotate.db.profile.channelType == "SAY" or CombRotate.db.profile.channelType == "YELL")
        ) then
            CombRotate:printPrefixedMessage(chatMessage .. " " .. L["YELL_SAY_DISABLED_OPEN_WORLD"])
            return
        end

        CombRotate:sendMessage(
            chatMessage,
            CombRotate.db.profile.channelType,
            CombRotate.db.profile.targetChannel
        )
    end
end

-- Send a rotation broadcast message
function CombRotate:sendRotationSetupBroadcastMessage(message)
    CombRotate:sendMessage(
        message,
        CombRotate.db.profile.rotationReportChannelType,
        CombRotate.db.profile.setupBroadcastTargetChannel
    )
end

-- Send a message to a given channel
function CombRotate:sendMessage(message, channelType, targetChannel)
    local channelNumber
    if channelType == "CHANNEL" then
        channelNumber = GetChannelName(targetChannel)
    end
    SendChatMessage(message, channelType, nil, channelNumber or targetChannel)
end

SLASH_COMBROTATE1 = "/comb"
SLASH_COMBROTATE2 = "/combrotate"
SlashCmdList["COMBROTATE"] = function(msg)
    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

    if (cmd == 'toggle') then
        CombRotate:toggleDisplay()
    elseif (cmd == 'lock') then
        CombRotate:lock(true)
    elseif (cmd == 'unlock') then
        CombRotate:lock(false)
    elseif (cmd == 'backup') then
        CombRotate:alertBackup(CombRotate.db.profile.unableToCombMessage)
    elseif (cmd == 'rotate') then -- @todo decide if this should be removed or not (Used in runDemo)
        CombRotate:testRotation()
    elseif (cmd == 'test') then
        CombRotate:toggleFireBlastTesting()
    elseif (cmd == 'report') then
        CombRotate:printRotationSetup()
    elseif (cmd == 'settings') then
        CombRotate:openSettings()
    elseif (cmd == 'check') then
        CombRotate:checkVersions()
    else
        CombRotate:printHelp()
    end
end

function CombRotate:toggleDisplay()
    if (CombRotate.mainFrame:IsShown()) then
        CombRotate.mainFrame:Hide()
        CombRotate:printMessage(L['COMB_WINDOW_HIDDEN'])
    else
        CombRotate.mainFrame:Show()
    end
end

-- Open ace settings
function CombRotate:openSettings()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    AceConfigDialog:Open("CombustionRotate")
end

-- Sends rotation setup to raid channel
function CombRotate:printRotationSetup()

    if (IsInRaid()) then
        CombRotate:sendRotationSetupBroadcastMessage('--- ' .. CombRotate.constants.printPrefix .. L['BROADCAST_HEADER_TEXT'] .. ' ---')

        if (CombRotate.db.profile.useMultilineRotationReport) then
            CombRotate:printMultilineRotation(CombRotate.rotationTables.rotation)
        else
            CombRotate:sendRotationSetupBroadcastMessage(
                CombRotate:buildGroupMessage(L['BROADCAST_ROTATION_PREFIX'] .. ' : ', CombRotate.rotationTables.rotation)
            )
        end

        if (#CombRotate.rotationTables.backup > 0) then
            CombRotate:sendRotationSetupBroadcastMessage(
                CombRotate:buildGroupMessage(L['BROADCAST_BACKUP_PREFIX'] .. ' : ', CombRotate.rotationTables.backup)
            )
        end
    end
end

-- Print the main rotation on multiple lines
function CombRotate:printMultilineRotation(rotationTable, channel)
    local position = 1;
    for key, mage in pairs(rotationTable) do
        CombRotate:sendRotationSetupBroadcastMessage(tostring(position) .. ' - ' .. mage.name)
        position = position + 1;
    end
end

-- Serialize mage names of a given rotation group
function CombRotate:buildGroupMessage(prefix, rotationTable)
    local mages = {}

    for key, mage in pairs(rotationTable) do
        table.insert(mages, CombRotate:formatPlayerName(mage.name))
    end

    return prefix .. table.concat(mages, ', ')
end

-- Print command options to chat
function CombRotate:printHelp()
    local spacing = '   '
    CombRotate:printMessage(CombRotate:colorText('/combrotate') .. ' commands options :')
    CombRotate:printMessage(spacing .. CombRotate:colorText('toggle') .. ' : Show/Hide the main window')
    CombRotate:printMessage(spacing .. CombRotate:colorText('lock') .. ' : Lock the main window position')
    CombRotate:printMessage(spacing .. CombRotate:colorText('unlock') .. ' : Unlock the main window position')
    CombRotate:printMessage(spacing .. CombRotate:colorText('settings') .. ' : Open CombustionRotate settings')
    CombRotate:printMessage(spacing .. CombRotate:colorText('report') .. ' : Prints the rotation setup to the configured channel')
    CombRotate:printMessage(spacing .. CombRotate:colorText('backup') .. ' : Whispers backup mages to immediately use combustion')
    CombRotate:printMessage(spacing .. CombRotate:colorText('check') .. ' : Prints users version of CombustionRotate')
    CombRotate:printMessage(spacing .. CombRotate:colorText('test') .. ' : Toggle test mode')
end

-- Adds color to given text
function CombRotate:colorText(text)
    return '|cffffbf00' .. text .. '|r'
end

-- Toggle fire blast testing mode
function CombRotate:toggleFireBlastTesting(disable)

    if (not disable and not CombRotate.testMode) then
        CombRotate:printPrefixedMessage(L['FIRE_BLAST_TESTING_ENABLED'])
        CombRotate.testMode = true

        -- Disable testing after 10 minutes
        C_Timer.After(600, function()
            CombRotate:toggleFireBlastTesting(true)
        end)
    else
        CombRotate.testMode = false
        CombRotate:printPrefixedMessage(L['FIRE_BLAST_TESTING_DISABLED'])
    end
end

-- Update the addon version of a given player
function CombRotate:updatePlayerAddonVersion(player, version)
    CombRotate.addonVersions[player] = version

    local mage = CombRotate:getMage(player)
    if (mage) then
        CombRotate:updateBlindIcon(mage)
    end

    local updateRequired, breakingUpdate = CombRotate:isUpdateRequired(version)
    if (updateRequired) then
        CombRotate:notifyUserAboutAvailableUpdate(breakingUpdate)
    end
end

-- Prints to the chat the addon version of every mage and addon users
function CombRotate:checkVersions()
    CombRotate:printPrefixedMessage("## " .. L["VERSION_CHECK_HEADER"] .. " ##")
    CombRotate:printPrefixedMessage(L["VERSION_CHECK_YOU"] .. " - " .. CombRotate.version)

    for player, version in pairs(CombRotate.addonVersions) do
        if (player ~= UnitName("player")) then
            CombRotate:printPrefixedMessage(CombRotate:formatPlayerName(player) .. " - " .. CombRotate:formatAddonVersion(version))
        end
    end
end

-- Removes players that left the raid from version table
function CombRotate:purgeAddonVersions()
    for player, version in pairs(CombRotate.addonVersions) do
        if (not UnitInParty(player)) then
            CombRotate.addonVersions[player] = nil
        end
    end
end

-- Returns a string based on the mage addon version
function CombRotate:formatAddonVersion(version)
    if (version == nil) then
        return L["VERSION_CHECK_NONE_OR_BELOW_1.0.0"]
    else
        return version
    end
end

-- Demo rotation to record documentation gifs / screens
function CombRotate:runDemo()
    C_Timer.NewTicker(
        10.5,
        function()
            CombRotate:startBossFrenzyCooldown(10)
            C_Timer.After(
                 1,
                function()
                    CombRotate:testRotation()
                end
            )
        end,
        5
    )
end

-- Parse version string
-- @return major, minor, fix, isStable
function CombRotate:parseVersionString(versionString)

    local version, versionType = strsplit("-", versionString)
    local major, minor, fix = strsplit( ".", version)

    return tonumber(major), tonumber(minor), tonumber(fix), versionType == nil
end

-- Check if the given version would require updating
-- @return requireUpdate, breakingUpdate
function CombRotate:isUpdateRequired(versionString)

    if (nil == versionString) then return false, false end

    local remoteMajor, remoteMinor, remoteFix, isRemoteStable = self:parseVersionString(versionString)
    local localMajor, localMinor, localFix, isLocalStable = self:parseVersionString(CombRotate.version)

    if (isRemoteStable) then

        if (remoteMajor > localMajor) then
            return true, true
        elseif (remoteMajor < localMajor) then
            return false, false
        end

        if (remoteMinor > localMinor) then
            return true, false
        elseif (remoteMinor < localMinor) then
            return false, false
        end

        if (remoteFix > localFix) then
            return true, false
        end
    end

    return false, false
end

-- Notify user about a new version available
function CombRotate:notifyUserAboutAvailableUpdate(isBreakingUpdate)
    if (isBreakingUpdate) then
        if (CombRotate.notifiedBreakingUpdate ~= true) then
            CombRotate:printPrefixedMessage('|cffff3d3d' .. L['BREAKING_UPDATE_AVAILABLE'] .. '|r')
            CombRotate.notifiedBreakingUpdate = true
        end
    else
        if (CombRotate.notifiedUpdate ~= true and CombRotate.notifiedBreakingUpdate ~= true) then
            CombRotate:printPrefixedMessage(L['UPDATE_AVAILABLE'])
            CombRotate.notifiedUpdate = true
        end
    end
end