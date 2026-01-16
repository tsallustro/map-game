extends Node

signal data_loaded
signal province_owner_changed(province_id: String, new_owner: String)
signal view_mode_changed(mode: int)
signal selection_changed(province_id: String)
signal date_changed(date: int)
signal speed_changed(speed: int)
signal province_infrastructure_changed(province_id: String)

var view_mode: int = Enums.ViewMode.OWNER

# Raw loaded data
var countries: Dictionary = {}          			# "NWT" -> {name, color:[r,g,b], type}
var provinces: Array = []               			# ordered list of province dicts
var terrain: Array = []								# ordered list of terrain dicts
var government_types : Array = []					# ordered list of government type dicts

# Derived indices (fast lookups)
var country_color: Dictionary = {}      			# "NWT" -> Color (0..1)
var province_index_by_id: Dictionary = {}       	# "p_blue" -> 1
var province_index_by_maskkey: Dictionary = {}  	# "235,42,255" -> 0
var province_terrain_by_id: Dictionary = {} 		# "p_yellow" -> Enums.TerrainType.DESERT
var terrain_color : Dictionary = {}					# Enums.TerrainType.DESERT -> color
var government_type_color : Dictionary = {}			# Enums.GovernmentType.TRIBAL -> color 
var province_infra_by_id : Dictionary = {}			# "p_yellow" -> 2

# Other common vars
var selected_province_id: String = ""
var time := 0
var timePerTick := 5								# In seconds
var tickTimeRemaining := float(timePerTick)
var speed := 1										# A tick occurs every (timePerTick / speed) seconds

func _ready() -> void:
	call_deferred("load_all")

func _process(delta: float) -> void:
	# Typical delta: 0.00833333333333 | 120 deltas per second
	var newTimeRemaining = tickTimeRemaining- delta*speed
	if(newTimeRemaining <= 0.0):
		print("WARN: Overshot tick by "+str(newTimeRemaining))
		time = time+1
		on_tick_update()
		tickTimeRemaining = newTimeRemaining + float(timePerTick)
	else:
		tickTimeRemaining = newTimeRemaining

func load_all() -> void:
	print("Loading JSON data...")
	countries = _load_json_dict("res://data/countries.json")
	provinces = _load_json_array("res://data/provinces.json")
	terrain = _load_json_array("res://data/terrain.json")
	government_types = _load_json_array("res://data/government_types.json")

	_validate_data()
	print("Successfully loaded JSON")
	print("Found "+str(provinces.size())+" provinces from data")

	print("Building indexes...")
	_build_indexes()
	print("Indexes built")
	emit_signal("data_loaded")

func _build_indexes() -> void:

	# Country indexing
	country_color.clear()
	for cid in countries.keys():
		var rgb: Array = countries[cid]["color"]
		country_color[cid] = _rgb_to_color(rgb)

	# Terrain color indexing
	terrain_color.clear()
	for t in range(terrain.size()):
		var terrain_data = terrain[t]
		var terrain_id = Enums.TerrainType.get(terrain_data["name"], -1)
		var rgb = terrain_data["color"]
		terrain_color[terrain_id] = _rgb_to_color(rgb)

	# print("Loaded %d colors from %d terrains"%[terrain_color.size(), terrain.size()])

	# Government type color indexing
	government_type_color.clear()
	for gt in range(government_types.size()):
		var gt_data = government_types[gt]
		var gt_id = Enums.GovernmentType.get(gt_data["name"], -1)
		var rgb = gt_data["color"]
		government_type_color[gt_id] = _rgb_to_color(rgb)
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

		var province_infra : int = p["infrastructure"]
		province_infra_by_id[pid] = province_infra

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

func _validate_data() -> void:
	print("Validating province data...")
	for i in range(provinces.size()):
		var provinceI = provinces[i]
		for j in range(i+1, provinces.size()):
			var provinceJ = provinces[j]
			if(provinceI["id"] == provinceJ["id"]):
				print("WARN: Duplicate province key \"%s\"" %[provinceI["id"]])
				# TODO validate colors
				
	# TODO validate country data

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

func get_province_owner_id_by_pid(province_id: String) -> String:
	var idx : int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
		return ""

	return provinces[idx]["owner"] 

func get_province_terrain_by_id(province_id: String) -> int:
	return province_terrain_by_id.get(province_id, -1)

func get_province_terrain_color_by_id(province_id: String) -> Color:
	return terrain_color[get_province_terrain_by_id(province_id)]

func get_gt_color_by_country_id(country_id: String) -> Color:
	var government_type = Enums.GovernmentType.get(countries[country_id]["type"],-1)
	return government_type_color[government_type]

func get_country_name_by_country_id(country_id : String)-> String:
	return countries[country_id]["name"] if country_id in countries else "UNKNOWN"

func get_province_infra_by_id(province_id: String) -> int:
	return province_infra_by_id[province_id]

func get_total_infra_by_country_id(country_id: String) -> int:
	var total = 0
	for p in provinces:
		if p["owner"] == country_id: total += p["infrastructure"]
	return total

func inc_province_infrastructure(province_id : String) -> void:
	var idx : int = province_index_by_id.get(province_id, -1)
	if idx == -1:
		push_error("Unknown province_id: " + province_id)
	var prev_infra = int(provinces[idx]["infrastructure"])
	var new_infra = prev_infra + 1
	provinces[idx]["infrastructure"] = new_infra

	# Update index
	province_infra_by_id[province_id] = new_infra
	emit_signal("province_infrastructure_changed", province_id)

func inc_selected_province_infrastructure() -> void:
	inc_province_infrastructure(selected_province_id)

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
