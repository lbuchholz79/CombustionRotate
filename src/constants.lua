CombRotate.colors = {
    ['blue'] = CreateColor(0.25, 0.78, 0.92),   -- #3FC7EB
    ['header'] = CreateColor(1.0, 0.81, 0.0),   -- #FDD000
    ['shadow'] = CreateColor(0.7, 0.3, 0.3),    -- red
    ['headerBg'] = CreateColor(0.48, 0.1, 0.0), -- #7C3800
    ['red'] = CreateColor(0.7, 0.3, 0.3),
    ['gray'] = CreateColor(0.3, 0.3, 0.3),
    ['purple'] = CreateColor(0.71,0.45,0.75),
    ['white'] = CreateColor(1,1,1),
}

CombRotate.constants = {
    ['className'] = 'MAGE',
    ['spellId'] = 11129,        -- Combustion
    ['testingSpellId'] = 2136,  -- Fire Blast (Rank 1)
    ['cooldownTime'] = 180,
    ['cooldownTimeTest'] = 8,
    ['mageFrameHeight'] = 22,
    ['mageFrameSpacing'] = 4,
    ['titleBarHeight'] = 18,
    ['mainFrameWidth'] = 150,
    ['rotationFramesBaseHeight'] = 20,

    ['commsPrefix'] = 'combrotate',
    ['commsChannel'] = 'RAID',

    ['commsTypes'] = {
        ['combDone'] = 'combustion-done',
        ['syncOrder'] = 'sync-order',
        ['syncRequest'] = 'sync-request',
        ['backupRequest'] = 'backup-request',
        ['reset'] = 'reset',
    },

    ['printPrefix'] = 'CombustionRotate - ',
    ['duplicateCombustionDelayThreshold'] = 10,

    ['sounds'] = {
        ['nextToComb'] = 'Interface\\AddOns\\CombustionRotate\\sounds\\ding.ogg',
        ['alarms'] = {
            ['alarm1'] = 'Interface\\AddOns\\CombustionRotate\\sounds\\alarm.ogg',
            ['alarm2'] = 'Interface\\AddOns\\CombustionRotate\\sounds\\alarm2.ogg',
            ['alarm3'] = 'Interface\\AddOns\\CombustionRotate\\sounds\\alarm3.ogg',
            ['alarm4'] = 'Interface\\AddOns\\CombustionRotate\\sounds\\alarm4.ogg',
            ['flagtaken'] = 'Sound\\Spells\\PVPFlagTaken.ogg',
        }
    },

    ['combNowSounds'] = {
        ['alarm1'] = 'Loud BUZZ',
        ['alarm2'] = 'Gentle beeplip',
        ['alarm3'] = 'Gentle dong',
        ['alarm4'] = 'Light bipbip',
        ['flagtaken'] = 'Flag Taken (DBM)',
    },

    ['fireImmuneTargets'] = {
        9017,  -- Lord Incendius
        11668, -- Firelord
        11666, -- Firewalker
        8909,  -- Fireguard
        12056, -- Geddon
        11502, -- Ragnaros
        13020, -- Vaelastrasz
        11983, -- Firemaw
        11981, -- Flamegor
        14601, -- Ebonroc
        11583, -- Nefarian
    },

    ["incapacitatingDebuffs"] = {
        19408, -- Magmadar fear
        23171, -- Chromaggus Bronze affliction stun
        23311, -- Chromaggus Time lapse
        29685, -- Gluth fear
    },

    ["playerNameFormats"] = {
        ["SHORT"] = "SHORT",
        ["PLAYER_NAME_ONLY"] = "PLAYER_NAME",
        ["FULL_NAME"] = "FULL_NAME",
    }
}
