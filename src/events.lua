local combustion = GetSpellInfo(11129)
local fireBlast = GetSpellInfo(10199)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ENCOUNTER_END")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if (event == "PLAYER_LOGIN") then
            CombRotate:init()
            self:UnregisterEvent("PLAYER_LOGIN")

            -- Delayed raid update because raid data is unreliable at PLAYER_LOGIN
            C_Timer.After(5, function()
                CombRotate:updateRaidStatus()
            end)
        else
            CombRotate[event](CombRotate, ...)
        end
    end
)

function CombRotate:COMBAT_LOG_EVENT_UNFILTERED()

    -- @todo : Improve this with register / unregister event to save resources
    -- Avoid parsing combat log when not able to use it
    if (not CombRotate.raidInitialized) then return end
    -- Avoid parsing combat log when outside instance if test mode isn't enabled
    if (not CombRotate.testMode and not IsInInstance()) then return end

    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())

    if (spellName == combustion or (CombRotate.testMode and spellName == fireBlast)) then
        local mage = CombRotate:getMage(sourceGUID)
        if (mage) then
            if (event == "SPELL_CAST_SUCCESS") then
                CombRotate:sendSyncComb(mage, false, timestamp)
                CombRotate:rotate(mage)
                if  (sourceGUID == UnitGUID("player")) then
                    CombRotate:sendAnnounceMessage(
                        CombRotate:getCombSuccessMessage(
                            destName,
                            destRaidFlags
                        )
                    )
                end
            elseif (CombRotate:isBossFireImmune(UnitGUID("target"))) then
                CombRotate:sendSyncComb(mage, true, timestamp, event)
                if  (sourceGUID == UnitGUID("player")) then
                    CombRotate:sendAnnounceMessage(CombRotate:getCombImmuneMessage(destName, destRaidFlags))
                end
            end
        end
    elseif (event == "SPELL_AURA_APPLIED" and not CombRotate:isBossFireImmune(sourceGUID)) then
        if (CombRotate:isPlayerNextComb()) then
            CombRotate:throwCombAlert()

            if (CombRotate.db.profile.enableIncapacitatedBackupAlert and CombRotate:isPlayedIncapacitatedByDebuff()) then
                CombRotate:alertBackup(CombRotate.db.profile.unableToCombMessage)
            end
        end
    elseif (event == "UNIT_DIED" and not CombRotate:isBossFireImmune(destGUID)) then
        if (CombRotate:isPlayerAllowedToManageRotation()) then
            CombRotate:endEncounter()
        end
    end
end

-- Raid group has changed
function CombRotate:GROUP_ROSTER_UPDATE()
    CombRotate:updateRaidStatus()
end

-- Player left combat
function CombRotate:PLAYER_REGEN_ENABLED()
    CombRotate:updateRaidStatus()
end

-- Player left combat
function CombRotate:ENCOUNTER_END()
    CombRotate.endEncounter()
end

function CombRotate:PLAYER_TARGET_CHANGED()
    if (CombRotate.db.profile.showWindowWhenTargetingBoss) then
        if (not CombRotate:isBossFireImmune(UnitGUID("target")) and not UnitIsDead("target")) then
            CombRotate.mainFrame:Show()
        end
    end
end

-- Register single unit events for a given mage
function CombRotate:registerUnitEvents(mage)

    mage.frame:RegisterUnitEvent("PARTY_MEMBER_DISABLE", mage.name)
    mage.frame:RegisterUnitEvent("PARTY_MEMBER_ENABLE", mage.name)
    mage.frame:RegisterUnitEvent("UNIT_HEALTH", mage.name)
    mage.frame:RegisterUnitEvent("UNIT_CONNECTION", mage.name)
    mage.frame:RegisterUnitEvent("UNIT_FLAGS", mage.name)

    mage.frame:SetScript(
        "OnEvent",
        function(self, event, ...)
            CombRotate:updateMageStatus(mage)
        end
    )

end

-- Unregister single unit events for a given mage
function CombRotate:unregisterUnitEvents(mage)
    mage.frame:UnregisterEvent("PARTY_MEMBER_DISABLE")
    mage.frame:UnregisterEvent("PARTY_MEMBER_ENABLE")
    mage.frame:UnregisterEvent("UNIT_HEALTH_FREQUENT")
    mage.frame:UnregisterEvent("UNIT_CONNECTION")
    mage.frame:UnregisterEvent("UNIT_FLAGS")
end
