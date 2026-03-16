extends Node

signal data_loaded
signal province_owner_changed(province_id: String, new_owner: String)
signal view_mode_changed(mode: int)
signal selection_changed(province_id: String)
signal date_changed(new_date: int)
signal speed_changed(speed: int)
signal province_infrastructure_changed(province_id: String)
signal pause_state_changed(isPaused: bool)

signal force_reload_TL_panel()
signal selected_country_changed(country_id: String)
var view_mode: int = Enums.ViewMode.OWNER

# Raw loaded data
var countries: Dictionary = {} # "NWT" -> {name, color:[r,g,b], type}
var non_existant_countries: Dictionary = {} # "NWT" -> {name, color:[r,g,b], type}
var provinces: Array = [] # ordered list of province dicts
var terrain: Array = [] # ordered list of terrain dicts
var government_types: Array = [] # ordered list of government type dicts

# Derived indices (fast lookups)
var country_color: Dictionary = {} # "NWT" -> Color (0..1)
var province_index_by_id: Dictionary = {} # "p_blue" -> 1
var province_index_by_maskkey: Dictionary = {} # "235,42,255" -> 0
var province_terrain_by_id: Dictionary = {} # "p_yellow" -> Enums.TerrainType.DESERT
var terrain_color: Dictionary = {} # Enums.TerrainType.DESERT -> color
var government_type_color: Dictionary = {} # Enums.GovernmentType.TRIBAL -> color
var province_infra_by_id: Dictionary = {} # "p_yellow" -> 2
var province_count_by_country_id: Dictionary = {} # "NWT" -> 1
var total_infra_by_country_id: Dictionary = {} # "NWT" -> 10
var money_by_country_id: Dictionary = {} # "NWT" -> 100

var flags: Dictionary = {
	"global": []
}

# Other common vars
var INITIAL_DATE = Time.get_datetime_dict_from_datetime_string("1000-01-01T00:00:00", false)
var selected_province_id: String = ""
var selected_country_id: String = ""
var current_date: Dictionary = INITIAL_DATE # { "year": 1000, "month": 1, "day": 2, "weekday": 4, "hour": 0, "minute": 0, "second": 0 }
var timePerTick := 2 # In seconds
var tickTimeRemaining := float(timePerTick)
var speed := 1 # A tick occurs every (timePerTick / speed) seconds
var isPaused = true

var is_loaded = false
var player_tag = "NOTAG"
func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if !isPaused:
		# Typical delta: 0.00833333333333 | 120 deltas per second
		var newTimeRemaining = tickTimeRemaining - delta * speed
		if (newTimeRemaining <= 0.0):
			# print("WARN: Overshot tick by " + str(newTimeRemaining))
			var previous_date = current_date.duplicate(true)
			_increment_date()
			_on_tick_update(previous_date)
			tickTimeRemaining = newTimeRemaining + float(timePerTick)
		else:
			tickTimeRemaining = newTimeRemaining

func load_all() -> void:
	print("Loading JSON data...")
	countries = Utils.load_json_dict("res://data/countries.json")
	provinces = Utils.load_json_array("res://data/provinces.json")
	_load_static_data()

	_validate_data()
	print("Successfully loaded JSON")
	print("Found " + str(provinces.size()) + " provinces from data")

	print("Building indexes...")
	_build_indexes()
	print("Indexes built")
	is_loaded = true
	emit_signal("data_loaded")

func _load_static_data() -> void:
	terrain = Utils.load_json_array("res://data/terrain.json")
	government_types = Utils.load_json_array("res://data/government_types.json")

func _build_indexes() -> void:
	# Country indexing
	country_color.clear()
	for cid in countries.keys():
		var rgb: Array = countries[cid]["color"]
		country_color[cid] = Utils.rgb_to_color(rgb)
		province_count_by_country_id[cid] = 0
		total_infra_by_country_id[cid] = 0
		money_by_country_id[cid] = countries[cid]["money"]
		if not "stability" in countries[cid]:
			countries[cid]["stability"] = 0
		if not "diplomacy" in countries[cid]:
			countries[cid]["diplomacy"] = {}
			for other_cid in countries.keys():
				if cid == other_cid: continue
				countries[cid]["diplomacy"][other_cid] = 0
	
	# Terrain color indexing
	terrain_color.clear()
	for t in range(terrain.size()):
		var terrain_data = terrain[t]
		var terrain_id = Enums.TerrainType.get(terrain_data["name"], -1)
		var rgb = terrain_data["color"]
		terrain_color[terrain_id] = Utils.rgb_to_color(rgb)

	# print("Loaded %d colors from %d terrains"%[terrain_color.size(), terrain.size()])

	# Government type color indexing
	government_type_color.clear()
	for gt in range(government_types.size()):
		var gt_data = government_types[gt]
		var gt_id = Enums.GovernmentType.get(gt_data["name"], -1)
		var rgb = gt_data["color"]
		government_type_color[gt_id] = Utils.rgb_to_color(rgb)
	# print("Loaded %d colors from %d government types"%[government_type_color.size(), government_types.size()])

	# Province indexing
	province_index_by_id.clear()
	province_index_by_maskkey.clear()
	province_terrain_by_id.clear()
	province_infra_by_id.clear()

	for i in range(provinces.size()):
		var p: Dictionary = provinces[i]
		var pid: String = p["id"]
		province_index_by_id[pid] = i

		var mc: Array = p["mask_color"] # [r,g,b]
		var key := "%d,%d,%d" % [mc[0], mc[1], mc[2]]
		province_index_by_maskkey[key] = i

		var province_terrain: String = p["terrain"]
		province_terrain_by_id[pid] = Enums.TerrainType.get(province_terrain, -1)

		var province_infra: int = p["infrastructure"]
		province_infra_by_id[pid] = province_infra
		province_count_by_country_id[p["owner"]] = province_count_by_country_id[p["owner"]] + 1
		total_infra_by_country_id[p["owner"]] = total_infra_by_country_id[p["owner"]] + province_infra

	for country in countries:
		if province_count_by_country_id[country] == 0:
			_delete_country(country)
	
	print("Found %d extant countries, %d non-existant countries" % [countries.size(), non_existant_countries.size()])
	print("Found %d provinces" % [provinces.size()])
func _validate_data() -> void:
	print("Validating province data...")
	for i in range(provinces.size()):
		var provinceI = provinces[i]
		for j in range(i + 1, provinces.size()):
			var provinceJ = provinces[j]
			if (provinceI["id"] == provinceJ["id"]):
				print("WARN: Duplicate province key \"%s\"" % [provinceI["id"]])
				# TODO validate colors
				
	for i in range(countries.size()):
		var countryI = countries[i]
		for j in range(i + 1, countries.size()):
			var countryJ = countries[j]
			if (countryI == countryJ):
				print("WARN: Duplicate country key \"%s\"" % [countryI])

# View Modes
func set_view_mode(mode: int) -> void:
	if view_mode == mode:
		return
	view_mode = mode
	emit_signal("view_mode_changed", view_mode)

# Tick/time
func _on_tick_update(previous_date: Dictionary) -> void:
	if (current_date["month"] != previous_date["month"]):
		# Month tick
		for country in countries:
			add_money(country, total_infra_by_country_id[country])

	emit_signal("date_changed", current_date)

func _set_date(date_as_unix_time: int) -> void:
	current_date = Time.get_datetime_dict_from_unix_time(date_as_unix_time)
	emit_signal("date_changed", current_date)

func _increment_date() -> void:
	var unix := Time.get_unix_time_from_datetime_dict(current_date)
	unix += 86400 # Unix seconds per day
	current_date = Time.get_datetime_dict_from_unix_time(unix)

func dec_speed() -> void:
	speed = max(1, speed - 1)
	emit_signal("speed_changed", speed)

func inc_speed() -> void:
	speed = min(5, speed + 1)
	emit_signal("speed_changed", speed)

func _set_speed(new_speed: int) -> void:
	speed = max(min(5, new_speed), 1)
	emit_signal("speed_changed", speed)

func togglePause():
	isPaused = !isPaused
	emit_signal("pause_state_changed", isPaused)

func unPause():
	isPaused = false
	emit_signal("pause_state_changed", isPaused)
func pause():
	isPaused = true
	emit_signal("pause_state_changed", isPaused)
# Data/Index management
func set_province_owner(province_id: String, new_owner: String) -> void:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
		return
	var old_owner = provinces[idx]["owner"]
	provinces[idx]["owner"] = new_owner
	if (new_owner in non_existant_countries): _restore_country(new_owner)
	if (_country_requires_deletion(old_owner)): _delete_country(old_owner)

	# Update indexes
	province_count_by_country_id[new_owner] = province_count_by_country_id[new_owner] + 1
	province_count_by_country_id[old_owner] = province_count_by_country_id[old_owner] - 1
	total_infra_by_country_id[old_owner] = total_infra_by_country_id[old_owner] - province_infra_by_id[province_id]
	total_infra_by_country_id[new_owner] = total_infra_by_country_id[new_owner] + province_infra_by_id[province_id]

	emit_signal("province_owner_changed", province_id, new_owner)

func get_country_color(country_id: String) -> Color:
	return country_color.get(country_id, Color(1, 1, 1, 1))

func get_province_by_id(province_id: String) -> Dictionary:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		return {}
	return provinces[idx].duplicate(true)

func get_province_owner_id_by_pid(province_id: String) -> String:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
		return ""

	return provinces[idx]["owner"]

func get_province_terrain_by_id(province_id: String) -> int:
	return province_terrain_by_id.get(province_id, -1)

func get_province_terrain_color_by_id(province_id: String) -> Color:
	return terrain_color[get_province_terrain_by_id(province_id)]

func get_gt_color_by_country_id(country_id: String) -> Color:
	var government_type = Enums.GovernmentType.get(countries[country_id]["type"], -1)
	return government_type_color[government_type]

func get_mask_color_for_province(province_id: String) -> Color:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		return Color(0, 0, 0, 1)
	var mc: Array = provinces[idx]["mask_color"]
	return Utils.rgb_to_color(mc)

func get_country_name_by_country_id(country_id: String) -> String:
	return countries[country_id]["name"] if country_id in countries else "UNKNOWN"

func inc_province_infrastructure(province_id: String) -> void:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
	var prev_infra = int(provinces[idx]["infrastructure"])
	var new_infra = prev_infra + 1
	provinces[idx]["infrastructure"] = new_infra

	# Update index
	province_infra_by_id[province_id] = new_infra
	var owner_id = get_province_owner_id_by_pid(province_id)
	total_infra_by_country_id[owner_id] = total_infra_by_country_id[owner_id] + 1
	emit_signal("province_infrastructure_changed", province_id)

func inc_selected_province_infrastructure() -> void:
	inc_province_infrastructure(selected_province_id)


func country_id_exists_or_can_exist(country_id: String) -> bool:
	return country_id in countries || country_id in non_existant_countries

func country_id_exists(country_id: String) -> bool:
	return country_id in countries

func province_id_exists(province_id: String) -> bool:
	for p in provinces:
		if p["id"] == province_id: return true
	return false

func annex(annexer_country_id: String, annexee_country_id: String) -> void:
	print("%s annexed %s" % [annexer_country_id, annexee_country_id])
	for p in provinces:
		if (p["owner"] == annexee_country_id):
			set_province_owner(p["id"], annexer_country_id)
			

func _delete_country(country_id: String) -> void:
	non_existant_countries[country_id] = countries[country_id]
	countries.erase(country_id)
	print("%s no longer exists." % [country_id])

func _restore_country(country_id: String) -> void:
	countries[country_id] = non_existant_countries[country_id]
	non_existant_countries.erase(country_id)
	print("%s has returned!." % [country_id])

func _country_requires_deletion(country_id: String) -> bool:
	for p in provinces:
		if p["owner"] == country_id: return false
	return true

func add_money(country_id: String, amount: int) -> void:
	var new_amount = countries[country_id]["money"] + amount
	countries[country_id]["money"] = new_amount
	money_by_country_id[country_id] = new_amount
	emit_signal("force_reload_TL_panel")

func add_stability(country_id: String, amount: int) -> void:
	var new_amount = max(min(countries[country_id]["stability"] + amount, 5), -5)
	countries[country_id]["stability"] = new_amount
	emit_signal("force_reload_TL_panel")

func manage_global_flag(flag_name: String, set_flag: bool) -> void:
	if (!set_flag):
		# Clear flag
		if (not (flag_name in flags["global"])):
			print("WARN: Flag %s is not in list" % [flag_name])
		else:
			(flags["global"] as Array).erase(flag_name)
	else:
		# Set flag
		if (flag_name in flags["global"]):
			print("WARN: Flag %s already in list" % [flag_name])
		else:
			(flags["global"] as Array).append(flag_name)

# Province selection/highlight
func select_province_by_maskkey(mask_key: String) -> void:
	var idx: int = province_index_by_maskkey.get(mask_key, -1)
	if idx == -1:
		clear_selection()
		return
	var province_id: String = provinces[idx]["id"]
	select_province(province_id)

func select_province(province_id: String) -> void:
	if selected_province_id == province_id:
		return
	selected_province_id = province_id
	emit_signal("selection_changed", selected_province_id)

func clear_selection() -> void:
	if selected_province_id == "":
		return
	selected_province_id = ""
	emit_signal("selection_changed", selected_province_id)

# Country info selection
func select_country_by_province_maskkey(mask_key: String) -> void:
	var idx: int = province_index_by_maskkey.get(mask_key, -1)
	if idx == -1:
		clear_selected_country()
		return
	var province_id: String = provinces[idx]["id"]
	select_country(get_province_owner_id_by_pid(province_id))

func select_country(country_id: String):
	if selected_country_id == country_id:
		return
	selected_country_id = country_id
	emit_signal("selected_country_changed", selected_country_id)

func clear_selected_country():
	if selected_country_id == "":
		return
	selected_country_id = ""
	emit_signal("selected_country_changed", selected_country_id)
# Save/Load wrappers
func save_game_state(save_name: String) -> void:
	if (save_name == null || save_name.strip_edges().is_empty()): print("WARN: invalid save name %s"%[save_name])
	if !isPaused: togglePause()
	var save_metadata = {
		# Authoritative data (must be reloaded)
		"speed": speed,
		"game_date": Time.get_unix_time_from_datetime_dict(current_date),
		"player_tag": player_tag,

		# Non-authoritative data (used by main menu)
		"player_name_pretty": get_country_name_by_country_id(player_tag),
		"player_color": Utils.color_to_rgb(get_country_color(player_tag)),
		"save_date": Time.get_unix_time_from_system()
	}
	SaveLoadUtils.save_game(save_name, save_metadata, countries, non_existant_countries, provinces)

func load_game_state(save_name: String) -> void:
	if !isPaused: togglePause()
	var data_arr = SaveLoadUtils.load_game(save_name)

	# Process metadata
	var save_metadata = data_arr[0]
	print("METADATA " + str(save_metadata))
	_set_speed(save_metadata["speed"])
	_set_date(save_metadata["game_date"])
	player_tag = save_metadata["player_tag"]
	
	# Load world data
	countries = data_arr[1]
	non_existant_countries = data_arr[2]
	provinces = data_arr[3]
	_validate_data()
	_load_static_data()
	print("Building indexes...")
	_build_indexes()
	print("Indexes built")
	is_loaded = true
	emit_signal("data_loaded")
