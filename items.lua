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
PlaceObj('ModItemOptionNumber', {
	'name', "HourDelay",
	'DisplayName', "Message Delay (Hours)",
	'Help', "Delay in hours before showing another achievement progress message.",
	'DefaultValue', 1,
	'MinValue', 0,
	'MaxValue', 25,
}),
PlaceObj('ModItemOptionNumber', {
	'name', "SolDelay",
	'DisplayName', "Message Delay (Sol)",
	'Help', "Delay in sols before showing another achievement progress message.",
	'DefaultValue', 0,
	'MinValue', 0,
	'MaxValue', 7,
}),
}