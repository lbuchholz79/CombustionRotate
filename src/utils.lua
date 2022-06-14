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
    return UnitIsFeignDeath(mage.name) or not UnitIsDeadOrGhost(mage.name)
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
    return mage.lastCombTime <= GetTime() - CombRotate.constants.cooldownTime
end

-- Checks if a mage is eligible to combustion next
function CombRotate:isEligibleForNextComb(mage)
    local isCooldownShortEnough = mage.lastCombTime <= GetTime() - CombRotate.constants.cooldownTime
    return CombRotate:isMageAliveAndOnline(mage) and isCooldownShortEnough
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
function CombRotate:isBossFireImmune(guid)

    local bosses = CombRotate.constants.bosses
    local type, mobId = CombRotate:getIdFromGuid(guid)

    if (type == "Creature") then
        for i, bossId in ipairs(bosses) do
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
