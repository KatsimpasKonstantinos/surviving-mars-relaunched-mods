return {
	PlaceObj('ModItemCode', {
		'CodeFileName', "Code/Script.lua",
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "RemoveQuotes",
		'DisplayName', "Remove All Quotes",
		'Help', "Strips the flavor quotes from the bottom of all technology descriptions.",
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "ElonMusk",
		'DisplayName', "Replace Elon Musk",
		'Help', "Replaces Elon Musk tech quotes and names with Nwabudike Morgan (from Sid Meier's Alpha Centauri). Ignored for tech quotes if Remove All Quotes is enabled.",
		'DefaultValue', true,
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "VladimirPutin",
		'DisplayName', "Replace Vladimir Putin",
		'Help', "Replaces Vladimir Putin's tech quote with a quote by Soviet rocket engineer Sergei Korolev. Ignored if Remove All Quotes is enabled.",
		'DefaultValue', true,
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "RonaldReagan",
		'DisplayName', "Replace Ronald Reagan",
		'Help', "Replaces Ronald Reagan's tech quote and name with Jimmy Carter. Ignored for tech quotes if Remove All Quotes is enabled.",
		'DefaultValue', true,
	}),
	PlaceObj('ModItemOptionToggle', {
		'name', "Vegans",
		'DisplayName', "Neutral Vegan Description",
		'Help', "Replaces the joke in the Vegan trait description with a standard definition of veganism.",
		'DefaultValue', true,
	}),
}