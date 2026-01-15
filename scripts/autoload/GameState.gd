extends Node

signal data_loaded
signal province_owner_changed(province_id: String, new_owner: String)
signal view_mode_changed(mode: int)
signal selection_changed(province_id: String)
signal date_changed(date: int)
signal speed_changed(speed: int)

var view_mode: int = Enums.ViewMode.OWNER

# Raw loaded data
var countries: Dictionary = {}          		# "NWT" -> {name, color:[r,g,b]}
var provinces: Array = []               		# ordered list of province dicts
var terrain: Array = []							# ordered list of terrain dicts

# Derived indices (fast lookups)
var country_color: Dictionary = {}      		# "NWT" -> Color (0..1)
var province_index_by_id: Dictionary = {}       # "p_blue" -> 1
var province_index_by_maskkey: Dictionary = {}  # "235,42,255" -> 0
var province_terrain_by_id: Dictionary = {} 	# "p_yellow" -> Enums.TerrainType.DESERT
var terrain_color : Dictionary = {}				# Enums.TerrainType.DESERT -> color

# Other common vars
var selected_province_id: String = ""
var time := 0
var timePerTick := 5							# In seconds
var tickTimeRemaining := float(timePerTick)
var speed := 1									# A tick occurs every (timePerTick / speed) seconds

func _ready() -> void:
	call_deferred("load_all")

func _process(delta: float) -> void:
	# Typical delta: 0.00833333333333 | 120 deltas per second
	tickTimeRemaining-=(delta*speed)
	if(tickTimeRemaining <= 0.0):
		time = time+1
		on_tick_update()
		tickTimeRemaining = float(timePerTick)

func load_all() -> void:
	print("Loading JSON data...")
	countries = _load_json_dict("res://data/countries.json")
	provinces = _load_json_array("res://data/provinces.json")
	terrain = _load_json_array("res://data/terrain.json")

	_build_indexes()
	print("Successfully loaded JSON")
	emit_signal("data_loaded")

func _build_indexes() -> void:
	# Normalize country colors once
	country_color.clear()
	for cid in countries.keys():
		var rgb: Array = countries[cid]["color"]
		country_color[cid] = _rgb_to_color(rgb)

	# Province indexing + maskkey lookup (order is the JSON array order)
	terrain_color.clear()
	for t in range(terrain.size()):
		var terrain_data = terrain[t]
		var terrain_id = Enums.TerrainType.get(terrain_data["name"])
		var rgb = terrain_data["color"]
		terrain_color[terrain_id] = _rgb_to_color(rgb)

	province_index_by_id.clear()
	province_index_by_maskkey.clear()
	province_terrain_by_id.clear()
	for i in range(provinces.size()):
		var p: Dictionary = provinces[i]
		var pid: String = p["id"]
		province_index_by_id[pid] = i

		var mc: Array = p["mask_color"] # [r,g,b]
		var key := "%d,%d,%d" % [mc[0], mc[1], mc[2]]
		province_index_by_maskkey[key] = i

		var province_terrain: String = p["terrain"]
		province_terrain_by_id[pid] = Enums.TerrainType.get(province_terrain, -1)
	

func _load_json_dict(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var j := JSON.new()
	var err := j.parse(text)
	if err != OK:
		push_error("JSON parse failed (" + path + "): " + j.get_error_message())
		return {}
	return j.data as Dictionary

func _load_json_array(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	var j := JSON.new()
	var err := j.parse(text)
	if err != OK:
		push_error("JSON parse failed (" + path + "): " + j.get_error_message())
		return []
	return j.data as Array

# View Modes
func set_view_mode(mode: int) -> void:
	if view_mode == mode:
		return
	view_mode = mode
	emit_signal("view_mode_changed", view_mode)

# Tick/time
func on_tick_update() -> void:
	emit_signal("date_changed", time)

func dec_speed() -> void:
	speed = max(1, speed -1)
	emit_signal("speed_changed", speed)

func inc_speed() -> void:
	speed = min(5, speed+1)
	emit_signal("speed_changed", speed)


# Data/Index management
func set_province_owner(province_id: String, new_owner: String) -> void:
	var idx : int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
		return

	provinces[idx]["owner"] = new_owner
	emit_signal("province_owner_changed", province_id, new_owner)

func get_country_color(country_id: String) -> Color:
	return country_color.get(country_id, Color(1, 1, 1, 1))

func get_province_by_id(province_id: String) -> Dictionary:
	var idx : int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		return {}
	return provinces[idx]

func get_province_terrain_by_id(province_id: String) -> int:
	return province_terrain_by_id.get(province_id, -1)

func get_province_terrain_color_by_id(province_id: String) -> Color:
	return terrain_color[get_province_terrain_by_id(province_id)]
	

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

# Utils
func get_mask_color_for_province(province_id: String) -> Color:
	var idx: int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		return Color(0, 0, 0, 1)
	var mc: Array = provinces[idx]["mask_color"]
	return _rgb_to_color(mc)

func _rgb_to_color(rgb: Array) -> Color:
	return Color(float(rgb[0]) / 255.0, float(rgb[1]) / 255.0, float(rgb[2]) / 255.0, 1.0)
