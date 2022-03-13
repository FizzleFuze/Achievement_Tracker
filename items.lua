local Achievements = {
	"None",
	"Aren't they Cute?",
	"Assisted Self-Improvement",
	"Asteroid Hopping",
	"Building a Better Future",
	"Can't Stop the Signal",
	"Do Androids Dream of Electric Sheep?",
	"Dream of a Green Mars",
	"Europa Universalis",
	"For the Benefit of All",
	"Gagarin's Legacy",
	"Interesting Times",
	"In the Service of Humankind",
	"Marsopolis",
	"Multiplanet Species",
	"No Pain, No Gain",
	"Posthuman",
	"Space Communism",
	"Space Explorer",
	"S.P.E.C.I.A.L.",
	"The Final Frontier",
	"The New Ark",
	"The New Wonders of the World",
	"Waste Not, Want Not",
	"Will they hold?",
	"Wubba, lubba, dub, dub!",
	"You can't take the Sky from Me!",
}

return {
	PlaceObj('ModItemCode', {
		'name', "Achievement",
		'comment', "Class Def",
		'FileName', "Code/TrackedAchievement.lua",
	}),
	PlaceObj('ModItemCode', {
		'name', "AchievementTracker",
		'comment', "Tracking Code",
		'FileName', "Code/AchievementTracker.lua",
	}),
	PlaceObj('ModItemCode', {
		'name', "On Screen Display",
		'comment', "OSD for Primary Achievement",
		'FileName', "Code/OSD.lua",
	}),
	PlaceObj('ModItemCode', {
		'name', "Colony Control Center",
		'comment', "CCC (Command Center) Additions for Achievements",
		'FileName', "Code/CCC.lua",
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "ShowFailures",
		'DisplayName', "Show Failure Messages",
		'Help', "Show a message when an achievement is failed",
		'DefaultValue', true,
	}),
	PlaceObj('ModItemOptionChoice', {
		'name', "DisplayMode",
		'DisplayName', "Display Mode",
		'Help', "Method(s) for displaying updates. OSD = On Screen Display",
		'DefaultValue', "Both",
		'ChoiceList', {
			"Messages",
			"OSD",
			"Both",
		},
	}),
	PlaceObj('ModItemOptionNumber', {
		'name', "MessageLength",
		'DisplayName', "Message Length (Real-Time Seconds)",
		'Help', "How long the message will show on the screen in seconds.",
		'DefaultValue', 10,
		'MinValue', 1,
		'MaxValue', 60,
	}),
	PlaceObj('ModItemOptionNumber', {
		'name', "SolDelay",
		'DisplayName', "Message Delay (Sols)",
		'Help', "Delay in sols before showing another achievement progress message",
		'DefaultValue', 0,
		'MinValue', 0,
		'MaxValue', 7,
	}),
	PlaceObj('ModItemOptionNumber', {
		'name', "HourDelay",
		'DisplayName', "Message Delay (Hours)",
		'Help', "Delay in hours before showing another achievement progress message",
		'DefaultValue', 1,
		'MinValue', 0,
		'MaxValue', 25,
	}),
	PlaceObj('ModItemOptionChoice', {
		'name', "TrackedAchievement",
		'DisplayName', "Tracked Achievements",
		'Help', "Toggle tracking of achievements in OSD",
		'DefaultValue', 'None',
		'ChoiceList', Achievements,
}),
}