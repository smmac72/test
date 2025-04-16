extends Node

## Simple JSON save/load that works in both desktop and Web.
## In Web export, the user:// path is stored in IndexedDB automatically.

var save_path := "user://save.json"

func save_game(state:Dictionary) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state, "  "))
		file.flush()

func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var txt = file.get_as_text()
		var obj = JSON.parse_string(txt)
		if typeof(obj) == TYPE_DICTIONARY:
			return obj
	return {}

func serialize_world() -> Dictionary:
	return {
		"global": {
			"money": GlobalState.money,
			"rep": GlobalState.reputation,
			"day": GlobalState.current_day
		},
		"upgrades": UpgradeManager.current_levels
	}

func restore_world(d:Dictionary):
	if d.has("global"):
		var g = d["global"]
		GlobalState.money = g.get("money", GlobalState.money)
		GlobalState.reputation = g.get("rep", GlobalState.reputation)
		GlobalState.current_day = g.get("day", GlobalState.current_day)
	if d.has("upgrades"):
		for k in d["upgrades"]:
			UpgradeManager.current_levels[k] = d["upgrades"][k]
