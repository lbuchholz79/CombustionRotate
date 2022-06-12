local L = CombRotate.L

function CombRotate:LoadDefaults()
	self.defaults = {
	    profile = {
			enableAnnounces = true,
			channelType = "YELL",
			rotationReportChannelType = "RAID",
			useMultilineRotationReport = false,
			announceBossSuccessMessage = L["DEFAULT_BOSS_SUCCESS_ANNOUNCE_MESSAGE"],
			announceTrashSuccessMessage = L["DEFAULT_TRASH_SUCCESS_ANNOUNCE_MESSAGE"],
			unableToCombMessage = L["DEFAULT_UNABLE_TO_COMB_MESSAGE"],
			lock = false,
			hideNotInRaid = false,
			enableNextToCombSound = true,
			enableCombNowSound = true,
			combNowSound = 'alarm1',
			doNotShowWindowOnRaidJoin = false,
			showWindowWhenTargetingBoss = false,
			enableIncapacitatedBackupAlert = true,
			incapacitatedDelay = 2,
			timedBackupAlertDelay = 3,
			showIconOnMageWithoutCombRotate = true,
			showBlindIconTooltip = true,
			playerNameFormatting = CombRotate.constants.playerNameFormats.PLAYER_NAME_ONLY,
	    },
	}
end
