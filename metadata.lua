return PlaceObj('ModDef', {
	'title', "Achievement Tracker",
	'description', "This mod is still a work in progress. Please hop in discord to help test and provide feedback. :)   https://discord.gg/kTgYq9UjWx",
	'image', "Images/thumbnail.png",
	'last_changes', "https://github.com/Surviving-Mars-Mods/Achievement-Tracker",
	'ignore_files', {
		"*.git/*",
		"*.svn/*",
		"src/*",
		"Info/2do.txt",
		"*.iml",
		".idea/*",
		"*.png",
	},
	'dependencies', {
		PlaceObj('ModDependency', {
			'id', "FIZZLE1",
			'title', "Fizzle Fuze's Library",
			'version_major', 1,
			'version_minor', 5,
		}),
	},
	'id', "FIZZLE3",
	'steam_id', "2755868001",
	'pops_desktop_uuid', "52a6e8c9-c772-45c5-a678-8db6896a8bcb",
	'pops_any_uuid', "3dab9f78-3c6f-4c5b-8ee7-9dfba90b9512",
	'author', "Fizzle Fuze",
	'version_major', 1,
	'version_minor', 10,
	'version', 69,
	'lua_revision', 1009413,
	'saved_with_revision', 1010838,
	'code', {
		"Code/TrackedAchievement.lua",
		"Code/AchievementTracker.lua",
		"Code/OSD.lua",
		"Code/CCC.lua",
	},
	'saved', 1645033554,
	'has_options', 'true',
	"TagInterface", true,
})