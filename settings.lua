data:extend{
	{
		type = "bool-setting",
		name = "miniloader-snapping",
		setting_type = "runtime-global",
		default_value = true,
		order = "miniloader-snapping",
	},
	{
		type = "bool-setting",
		name = "miniloader-item-restrictions",
		setting_type = "startup",
		default_value = true,
		order = "miniloader-item-restrictions",
	},
	{
		type = "string-setting",
		name = "miniloader-item-restrictions-class",
		setting_type = "runtime-global",
		default_value = "bulk",
		allowed_values = {"bulk", "bulk+plates"},
		order = "miniloader-item-restrictions-class",
	},
}