return {
	PlaceObj('ModItemCode', {
		'CodeFileName', "Code/Script.lua",
	}),
	PlaceObj('ModItemOptionNumber', {
		'name', "Interestrate",
		'DisplayName', "Interest Rate",
		'Help', "Default is 1%",
		'DefaultValue', 1,
		'MinValue', -10,
		'MaxValue', 10,
	}),
}