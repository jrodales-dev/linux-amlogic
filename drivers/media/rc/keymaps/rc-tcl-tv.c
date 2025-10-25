/* rc-tcl-tv.c - Keytable for TCL TV remote controls
 *
 * Copyright (c) 2025 Linux Amlogic Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <media/rc-map.h>
#include <linux/module.h>

/*
 * TCL TV remote controls typically use NEC protocol.
 * This keymap is compatible with common TCL TV remotes and can be used
 * with Amlogic S905X-based TV boxes.
 *
 * To use this keymap, configure your device tree to use:
 *   linux,rc-map-name = "rc-tcl-tv";
 *
 * Common TCL remote scancodes (NEC protocol):
 * Format: 0xAACC where AA = address (usually 0x04 or 0x14), CC = command
 */
static struct rc_map_table tcl_tv[] = {
	/* Power and basic controls */
	{ 0x0412, KEY_POWER },		/* Power button */
	{ 0x1412, KEY_POWER },		/* Power (alternate address) */
	{ 0x040c, KEY_MUTE },		/* Mute */
	{ 0x140c, KEY_MUTE },		/* Mute (alternate) */

	/* Number keys */
	{ 0x0400, KEY_0 },
	{ 0x0401, KEY_1 },
	{ 0x0402, KEY_2 },
	{ 0x0403, KEY_3 },
	{ 0x0404, KEY_4 },
	{ 0x0405, KEY_5 },
	{ 0x0406, KEY_6 },
	{ 0x0407, KEY_7 },
	{ 0x0408, KEY_8 },
	{ 0x0409, KEY_9 },

	/* Alternate number keys (different address) */
	{ 0x1400, KEY_0 },
	{ 0x1401, KEY_1 },
	{ 0x1402, KEY_2 },
	{ 0x1403, KEY_3 },
	{ 0x1404, KEY_4 },
	{ 0x1405, KEY_5 },
	{ 0x1406, KEY_6 },
	{ 0x1407, KEY_7 },
	{ 0x1408, KEY_8 },
	{ 0x1409, KEY_9 },

	/* Navigation */
	{ 0x0419, KEY_UP },
	{ 0x041a, KEY_DOWN },
	{ 0x041b, KEY_LEFT },
	{ 0x041c, KEY_RIGHT },
	{ 0x041d, KEY_OK },		/* OK/Enter */
	{ 0x041e, KEY_SELECT },		/* Select/Confirm */

	/* Alternate navigation */
	{ 0x1419, KEY_UP },
	{ 0x141a, KEY_DOWN },
	{ 0x141b, KEY_LEFT },
	{ 0x141c, KEY_RIGHT },
	{ 0x141d, KEY_OK },
	{ 0x141e, KEY_SELECT },

	/* Volume */
	{ 0x0410, KEY_VOLUMEUP },
	{ 0x0411, KEY_VOLUMEDOWN },
	{ 0x1410, KEY_VOLUMEUP },
	{ 0x1411, KEY_VOLUMEDOWN },

	/* Channel */
	{ 0x0413, KEY_CHANNELUP },
	{ 0x0414, KEY_CHANNELDOWN },
	{ 0x1413, KEY_CHANNELUP },
	{ 0x1414, KEY_CHANNELDOWN },

	/* Menu and Info */
	{ 0x0415, KEY_MENU },
	{ 0x0416, KEY_INFO },		/* Display/Info */
	{ 0x0417, KEY_EPG },		/* Guide/EPG */
	{ 0x1415, KEY_MENU },
	{ 0x1416, KEY_INFO },
	{ 0x1417, KEY_EPG },

	/* Navigation/Back */
	{ 0x0418, KEY_BACK },
	{ 0x0428, KEY_EXIT },
	{ 0x1418, KEY_BACK },
	{ 0x1428, KEY_EXIT },

	/* Source/Input */
	{ 0x040b, KEY_TV },		/* TV/Input source */
	{ 0x140b, KEY_TV },
	{ 0x040f, KEY_VIDEO },		/* Video/AV input */
	{ 0x140f, KEY_VIDEO },

	/* Media controls */
	{ 0x0420, KEY_PLAY },
	{ 0x0421, KEY_PAUSE },
	{ 0x0422, KEY_STOP },
	{ 0x0423, KEY_RECORD },
	{ 0x0424, KEY_REWIND },
	{ 0x0425, KEY_FASTFORWARD },
	{ 0x0426, KEY_PREVIOUS },
	{ 0x0427, KEY_NEXT },

	/* Alternate media controls */
	{ 0x1420, KEY_PLAY },
	{ 0x1421, KEY_PAUSE },
	{ 0x1422, KEY_STOP },
	{ 0x1423, KEY_RECORD },
	{ 0x1424, KEY_REWIND },
	{ 0x1425, KEY_FASTFORWARD },
	{ 0x1426, KEY_PREVIOUS },
	{ 0x1427, KEY_NEXT },

	/* Colored function keys */
	{ 0x0429, KEY_RED },
	{ 0x042a, KEY_GREEN },
	{ 0x042b, KEY_YELLOW },
	{ 0x042c, KEY_BLUE },
	{ 0x1429, KEY_RED },
	{ 0x142a, KEY_GREEN },
	{ 0x142b, KEY_YELLOW },
	{ 0x142c, KEY_BLUE },

	/* Additional common keys */
	{ 0x040d, KEY_TEXT },		/* Subtitle/Text */
	{ 0x040e, KEY_SUBTITLE },	/* Subtitle */
	{ 0x042d, KEY_HOME },		/* Home */
	{ 0x042e, KEY_SETUP },		/* Settings */
	{ 0x042f, KEY_SLEEP },		/* Sleep timer */
	{ 0x140d, KEY_TEXT },
	{ 0x140e, KEY_SUBTITLE },
	{ 0x142d, KEY_HOME },
	{ 0x142e, KEY_SETUP },
	{ 0x142f, KEY_SLEEP },
};

static struct rc_map_list tcl_tv_map = {
	.map = {
		.scan    = tcl_tv,
		.size    = ARRAY_SIZE(tcl_tv),
		.rc_type = RC_TYPE_NEC,
		.name    = RC_MAP_TCL_TV,
	}
};

static int __init init_rc_map_tcl_tv(void)
{
	return rc_map_register(&tcl_tv_map);
}

static void __exit exit_rc_map_tcl_tv(void)
{
	rc_map_unregister(&tcl_tv_map);
}

module_init(init_rc_map_tcl_tv)
module_exit(exit_rc_map_tcl_tv)

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Linux Amlogic Project");
MODULE_DESCRIPTION("TCL TV remote control keymap");
