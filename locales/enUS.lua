CombRotate = select(2, ...)

local L = {

    ["LOADED_MESSAGE"] = "CombustionRotate loaded, type /comb for options",
    ["COMB_WINDOW_HIDDEN"] = "CombustionRotate window hidden. Use /comb toggle to get it back",

    -- Buttons tooltips
    ["BUTTON_CLOSE"] = "Hide window",
    ["BUTTON_SETTINGS"] = "Settings",
    ["BUTTON_RESET_ROTATION"] = "Reset Rotation",
    ["BUTTON_PRINT_ROTATION"] = "Print Rotation",

    -- Settings
    ["SETTING_GENERAL"] = "General",
    ["SETTING_GENERAL_REPORT"] = "Please report any issue at",
    ["SETTING_GENERAL_DESC"] = "New : CombustionRotate will now play a sound when you need to apply your combustion! There are also few more display options to make the addon less intrusive.",

    ["LOCK_WINDOW"] = "Lock window",
    ["LOCK_WINDOW_DESC"] = "Lock window",
    ["RESET_WINDOW_POSITION"] = "Reset position",
    ["RESET_WINDOW_POSITION_DESC"] = "Reset the main window position",
    ["HIDE_WINDOW_NOT_IN_RAID"] = "Hide the window when not in a raid",
    ["HIDE_WINDOW_NOT_IN_RAID_DESC"] = "Hide the window when not in a raid",
    ["DO_NOT_SHOW_WHEN_JOINING_RAID"] = "Do not show window when joining a raid",
    ["DO_NOT_SHOW_WHEN_JOINING_RAID_DESC"] = "Check this if you don't want the window to show up each time you join a raid",
    ["SHOW_WHEN_TARGETING_BOSS"] = "Show window when you target a non fire-immune boss",
    ["SHOW_WHEN_TARGETING_BOSS_DESC"] = "Show window when you target a non fire-immune boss",
    ["WINDOW_LOCKED"] = "CombuistionRotate: Window locked",
    ["WINDOW_UNLOCKED"] = "CombustionRotate: Window unlocked",

    --- Player names formatting options
    ["PLAYER_NAME_FORMAT"] = "Player names format",
    ["PLAYER_NAME_FORMAT_DESC"] = "On connected realms, players from other servers will have a the server suffix hidden by default. If you ever get two mages with the exact same name, adjust this setting to your needs",
    ["PLAYER_NAME_ONLY_OPTION_LABEL"] = "Playername",
    ["SHORTENED_SUFFIX_OPTION_LABEL"] = "Playername-Ser",
    ["FULL_NAME_OPTION_LABEL"] = "Playername-Server",

    ["TEST_MODE_HEADER"] = "Test mode",
    ["ENABLE_FIRE_BLAST_TESTING"] = "Toggle testing mode",
    ["ENABLE_FIRE_BLAST_TESTING_DESC"] =
        "While testing mode is enabled, fire blast (rank 1) will be registered as a combustion\n" ..
        "Testing mode will last 10 minutes unless you toggle it off",
    ["FIRE_BLAST_TESTING_ENABLED"] = "Fire blast (rank 1) testing mode enabled for 10 minutes",
    ["FIRE_BLAST_TESTING_DISABLED"] = "Fire blast (rank 1) testing mode disabled",

    ["FEATURES_HEADER"] = "Optionals features",
    ["DISPLAY_BLIND_ICON"] = "Show an icon for mage without CombustionRotate",
    ["DISPLAY_BLIND_ICON_DESC"] = "Adds a blind icon on the mage frame to indicate he's not using the addon. This means he will not be aware of the rotate unless you communicate with him and his combustion won't be synced if he's far from every other CombustionRotate user.",
    ["DISPLAY_BLIND_ICON_TOOLTIP"] = "Show the blind icon tooltip",
    ["DISPLAY_BLIND_ICON_TOOLTIP_DESC"] = "You can disable this options to disable the tooltip while still having the icon",
    ["ENABLE_AUTOMATIC_BACKUP_ALERT_WHEN_INCAPACITATED"] = "Enable automatic backup alert when incapacitated",
    ["ENABLE_AUTOMATIC_BACKUP_ALERT_WHEN_INCAPACITATED_DESC"] = "CombustionRotate will check for your debuffs when you should actually apply combustion and will call for backup if you are incapacitated for longer than the defined delay",
    ["INCAPACITATED_DELAY_THRESHOLD"] = "Incapacitated alert threshold",
    ["INCAPACITATED_DELAY_THRESHOLD_DESC"] = "If you are incapacitated for longer than the configured delay, CombustionRotate will automatically call for backup",
    ["TIMED_DELAY_THRESHOLD"] = "Timed alert threshold",
    ["TIMED_DELAY_THRESHOLD_DESC"] = "CombustionRotate will automatically call for backup if you do not apply combustion within the configured threshold",

    --- Announces
    ["SETTING_ANNOUNCES"] = "Announces",
    ["ENABLE_ANNOUNCES"] = "Enable announces",
    ["ENABLE_ANNOUNCES_DESC"] = "Enable / disable the announcement.",
    ["YELL_SAY_DISABLED_OPEN_WORLD"] = "(Yell and say channels does not work in open world, but will inside your raids)",

    ---- Channels
    ["ANNOUNCES_CHANNEL_HEADER"] = "Announce channel",
    ["MESSAGE_CHANNEL_TYPE"] = "Send messages to",
    ["MESSAGE_CHANNEL_TYPE_DESC"] = "Channel you want to send messages",
    ["MESSAGE_CHANNEL_NAME"] = "Channel name",
    ["MESSAGE_CHANNEL_NAME_DESC"] = "Set the name of the target channel",

    ----- Channels types
    ["CHANNEL_CHANNEL"] = "Channel",
    ["CHANNEL_RAID_WARNING"] = "Raid Warning",
    ["CHANNEL_SAY"] = "Say",
    ["CHANNEL_YELL"] = "Yell",
    ["CHANNEL_PARTY"] = "Party",
    ["CHANNEL_RAID"] = "Raid",

    ---- Messages
    ["ANNOUNCES_MESSAGE_HEADER"] = "Announce messages",
    ["BOSS_SUCCESS_MESSAGE_LABEL"] = "Successful announce message on boss (%s will be replaced by next mage name)",
    ["TRASH_SUCCESS_MESSAGE_LABEL"] = "Successful announce message on trash (%s will be replaced by target name)",
    ["FAIL_IMMUNE_LABEL"] = "Target is fire immune!",
    ["UNABLE_TO_COMB_MESSAGE_LABEL"] = "Message whispered when you cannot apply comsution or call for backup",

    ['DEFAULT_BOSS_SUCCESS_ANNOUNCE_MESSAGE'] = "Combustion applied, %s is next!",
    ['DEFAULT_TRASH_SUCCESS_ANNOUNCE_MESSAGE'] = "Combustion applied on %s",
    ['DEFAULT_UNABLE_TO_COMB_MESSAGE'] = "I'M UNABLE TO APPLY COMBUSTION!",

    ['COMB_NOW_LOCAL_ALERT_MESSAGE'] = "USE COMBUSTION NOW !",

    ["BROADCAST_MESSAGE_HEADER"] = "Rotation setup text broadcast",
    ["USE_MULTILINE_ROTATION_REPORT"] = "Use multiline for main rotation when reporting",
    ["USE_MULTILINE_ROTATION_REPORT_DESC"] = "Check this option if you want more comprehensible order display",

    --- Raid broadcast messages
    ["BROADCAST_HEADER_TEXT"] = "Mage combustion setup",
    ["BROADCAST_ROTATION_PREFIX"] = "Rotation",
    ["BROADCAST_BACKUP_PREFIX"] = "Backup",

    --- Sounds
    ["SETTING_SOUNDS"] = "Sounds",
    ["ENABLE_NEXT_TO_COMB_SOUND"] = "Play a sound when you are the next to trigger combustion",
    ["ENABLE_COMB_NOW_SOUND"] = "Play a sound when you have to apply combustion",
    ["COMB_NOW_SOUND_CHOICE"] = "Select the sound you want to use for the 'apply combustion now' alert",

    --- Profiles
    ["SETTING_PROFILES"] = "Profiles",

    -- Blind icon tooltip
    ["TOOLTIP_PLAYER_WITHOUT_ADDON"] = "This player does not use CombustionRotate",
    ["TOOLTIP_MAY_RUN_OUDATED_VERSION"] = "Or runs an outdated version below 1.6.0",
    ["TOOLTIP_DISABLE_SETTINGS"] = "(You can disable this icon and/or this tooltip in the settings)",

    -- Available update
    ["UPDATE_AVAILABLE"] = "A new CombustionRotate version is available, update to get latest features",
    ["BREAKING_UPDATE_AVAILABLE"] = "A new BREAKING CombustionRotate update is available, you MUST update AS SOON AS possible! CombustionRotate may not work properly with up-to-date version users.",

    -- Rotation reset
    ["RESET_UNAUTHORIZED"] = "You must be raid assist to reset the rotation",

    -- Comms chat messages
    ["COMMS_SENT_BACKUP_REQUEST"] = "Sending backup request to %s",
    ["COMMS_RECEIVED_NEW_ROTATION"] = "Received new rotation configuration from %s",
    ["COMMS_RECEIVED_BACKUP_REQUEST"] = "%s asked for backup !",
    ["COMMS_RECEIVED_RESET_BROADCAST"] = "%s has reset the rotation.",

    -- Version check printed messages
    ["VERSION_CHECK_HEADER"] = "Version check",
    ["VERSION_CHECK_YOU"] = "You",
    ["VERSION_CHECK_NONE_OR_BELOW_1.0.0"] = "None or below 1.0.0",
}

CombRotate.L = L
