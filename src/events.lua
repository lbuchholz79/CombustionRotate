local combustion = GetSpellInfo(CombRotate.constants.spellId)
local testingSpell = GetSpellInfo(CombRotate.constants.testingSpellId)
local playerGUID = UnitGUID("player")

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if (event == "PLAYER_LOGIN") then
            if (CombRotate:isMage("player")) then
                eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
                eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
                eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
                eventFrame:RegisterEvent("ENCOUNTER_END")

                CombRotate:init()
                self:UnregisterEvent("PLAYER_LOGIN")

                -- Delayed raid update because raid data is unreliable at PLAYER_LOGIN
                C_Timer.After(5, function()
                    CombRotate:updateRaidStatus()
                end)
            else
                CombRotate:printMessage(CombRotate.L["UNLOADED_MESSAGE"])
            end
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

    if (spellName == combustion or (CombRotate.testMode and spellName == testingSpell)) then
        local sourceMage = CombRotate:getMage(sourceGUID)
        CombRotate:debug("Combustion detected from mage: " .. sourceMage .. " on target " .. destGUID)
        if (sourceMage) then
            if (event == "SPELL_CAST_SUCCESS") then
                CombRotate:debug("Combustion successful")
                CombRotate:sendSyncComb(sourceMage, false, timestamp)
                CombRotate:rotate(sourceMage)
                if (sourceGUID == playerGUID) then
                    CombRotate:sendAnnounceMessage(
                            CombRotate:getCombSuccessMessage(
                                    destName,
                                    destRaidFlags
                            )
                    )
                end
            elseif (event == "SPELL_MISSED") then
                CombRotate:debug("Combustion failed")
                CombRotate:sendSyncComb(sourceMage, true, timestamp, event)
                CombRotate:handleFailComb(sourceMage, event)
                if (sourceGUID == playerGUID) then
                    CombRotate:sendAnnounceMessage(
                            CombRotate:getCombFailMessage(
                                    CombRotate:isTargetFireImmune(destGUID),
                                    destName,
                                    destRaidFlags
                            )
                    )
                end
            end
        end
    elseif (event == "UNIT_DIED" and sourceGUID ~= UnitGUID("player") and not InCombatLockdown()) then
        CombRotate:debug("Target died")
        CombRotate:updateRaidStatus()
        if (CombRotate:isPlayerAllowedToManageRotation()) then
            CombRotate:endEncounter()
        end
    else
        CombRotate:debug("event happened: " .. event .. ", sourceGUID: " .. sourceGUID .. ", targetGUID: " .. destGUID)
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
    CombRotate:endEncounter()
end

function CombRotate:PLAYER_TARGET_CHANGED()
    if (CombRotate.db.profile.hideOnFireImmuneTarget) then
        if (CombRotate:isTargetFireImmune(UnitGUID("target")) and not UnitIsDead("target")) then
            CombRotate.mainFrame:Hide()
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
