-- Checks if player is incapacitated by a debuff for too long
function CombRotate:isPlayedIncapacitatedByDebuff()
    for i, debuffId in ipairs(CombRotate.constants.incapacitatingDebuffs) do
        local name, expirationTime = CombRotate:getPlayerDebuff(debuffId)
        if (name and expirationTime - GetTime() > CombRotate.db.profile.incapacitatedDelay) then
            return true
        end
    end

    return false
end

function CombRotate:getPlayerDebuff(debuffId)
    for i=1, 32, 1 do
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal,
        spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitDebuff("player", i)

        if (spellId and spellId == debuffId) then
            return name, expirationTime
        end
    end

    return nil
end
