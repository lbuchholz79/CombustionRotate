-- Check if a table contains the given element
function CombRotate:tableContains(table, element)

    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end

    return false
end

-- Checks if a mage is alive
function CombRotate:isMageAlive(mage)
    return UnitIsFeignDeath(mage.name) or not CombRotate:isUnitDead(mage.name)
end

function CombRotate:isUnitDead(name)
    return UnitIsDeadOrGhost(name)
end

-- Checks if a mage is offline
function CombRotate:isMageOnline(mage)
    return UnitIsConnected(mage.name)
end

-- Checks if a mage is online and alive
function CombRotate:isMageAliveAndOnline(mage)
    return CombRotate:isMageOnline(mage) and CombRotate:isMageAlive(mage)
end

-- Checks if a mage combustion is ready
function CombRotate:isMageCombustionCooldownReady(mage)
    return mage.lastCombTime <= GetTime() - CombRotate:getCooldownTime()
end

-- Get cooldown of combustion or testing delay
function CombRotate:getCooldownTime()
    if (CombRotate.testMode) then
        return CombRotate.constants.cooldownTimeTest
    else
        return CombRotate.constants.cooldownTime
    end
end

-- Checks if a mage is eligible to combustion next
function CombRotate:isEligibleForNextComb(mage)
    return CombRotate:isMageAliveAndOnline(mage) and CombRotate:isMageCombustionCooldownReady(mage)
end

-- Checks if a mage is in a battleground
function CombRotate:isPlayerInBattleground()
    return UnitInBattleground('player') ~= nil
end

-- Checks if a mage is in a PvE raid
function CombRotate:isInPveRaid()
    return IsInRaid() and not CombRotate:isPlayerInBattleground()
end

function CombRotate:getPlayerNameFont()
    return "Fonts\\ARIALN.ttf"
end

function CombRotate:getIdFromGuid(guid)
    local type, _, _, _, _, mobId, _ = strsplit("-", guid or "")
    return type, tonumber(mobId)
end

-- Checks if the mob is a fire immune boss
function CombRotate:isTargetFireImmune(guid)

    local immunes = CombRotate.constants.fireImmuneTargets
    local type, mobId = CombRotate:getIdFromGuid(guid)

    if (type == "Creature") then
        for i, bossId in ipairs(immunes) do
            if (bossId == mobId) then
                return true
            end
        end
    end

    return false
end

-- Checks if the player is a mage
function CombRotate:isMage(name)
    return select(2, UnitClass(name)) == CombRotate.constants.className
end

-- Check if unit is promoted (raid assist or raid leader)
function CombRotate:isPlayerRaidAssist(name)

    if (CombRotate:isInPveRaid()) then

        local raidIndex = UnitInRaid(name)

        if (raidIndex) then
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(raidIndex)

            if (rank > 0) then
                return true
            end
        end
    end

    return false
end

-- Checks if player is allowed to manage rotation
function CombRotate:isPlayerAllowedToManageRotation()
    local playerName = UnitName("player")
    return CombRotate:isUnitAllowedToManageRotation(playerName)
end

-- Checks if unit is allowed to manage rotation
function CombRotate:isUnitAllowedToManageRotation(unitName)
    return CombRotate:isMage(unitName) or CombRotate:isPlayerRaidAssist(unitName)
end

-- Format the player name and server suffix
function CombRotate:formatPlayerName(fullName)

    local displayName = fullName

    if (CombRotate.constants.playerNameFormats.SHORT == CombRotate.db.profile.playerNameFormatting) then
        local dashIndex = strfind(fullName, "-")
        if (nil ~= dashIndex) then
            displayName = strsub(fullName, 1, dashIndex + 3)
        end
    elseif (CombRotate.constants.playerNameFormats.PLAYER_NAME_ONLY == CombRotate.db.profile.playerNameFormatting) then
        displayName = strsplit("-", fullName)
    end

    return displayName
end
