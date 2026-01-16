extends Node

@export var map_sprite_path: NodePath = ^"../MapSprite"
@onready var map_sprite: Sprite2D = get_node(map_sprite_path)

var _mat: ShaderMaterial

func _ready() -> void:
	_mat = map_sprite.material as ShaderMaterial

	GameState.data_loaded.connect(_on_data_loaded)
	GameState.view_mode_changed.connect(_on_view_mode_changed)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.province_owner_changed.connect(_on_province_owner_changed)
	# If GameState loaded before we connected (rare, but possible), sync now:
	_sync_all()

func _sync_all() -> void:
	_on_view_mode_changed(GameState.view_mode)
	_on_selection_changed(GameState.selected_province_id)

func _on_data_loaded() -> void:
	print("Map renderer data loading...")
	_build_shader_arrays()
	_sync_all()
	print("Map renderer loaded")

func _build_shader_arrays() -> void:
	# prov_colors: mask colors in province array order
	var prov_arr := PackedColorArray()
	var owner_arr := PackedColorArray()
	var terrain_arr := PackedColorArray()
	var gt_arr := PackedColorArray()
	var infra_arr := PackedColorArray()

	var province_infra_values := Array()

	for p in GameState.provinces:
		var mc: Array = p["mask_color"]
		prov_arr.append(Color(mc[0]/255.0, mc[1]/255.0, mc[2]/255.0, 1.0))

		var owner_id: String = p["owner"]
		owner_arr.append(GameState.get_country_color(owner_id))

		var p_terrain_color := GameState.get_province_terrain_color_by_id(p["id"])
		terrain_arr.append(p_terrain_color)

		var p_gt_color : Color = GameState.get_gt_color_by_country_id(owner_id)
		gt_arr.append(p_gt_color)

		var p_infra_value := GameState.get_province_infra_by_id(p["id"])
		province_infra_values.append(p_infra_value)

	var max_infra = province_infra_values.max()
	var min_infra = province_infra_values.min()
	for i in range(province_infra_values.size()):
		var infra_value =  province_infra_values[i]
		var color = Utils.get_gradient_value_ryg(infra_value, min_infra, max_infra)
		infra_arr.append(color)

	_mat.set_shader_parameter("prov_colors", prov_arr)
	_mat.set_shader_parameter("owner_colors", owner_arr)
	_mat.set_shader_parameter("terrain_colors", terrain_arr)
	_mat.set_shader_parameter("gt_colors", gt_arr)
	_mat.set_shader_parameter("infra_colors", infra_arr)

func _on_view_mode_changed(mode: int) -> void:
	_mat.set_shader_parameter("view_mode", mode)

func _on_selection_changed(province_id: String) -> void:
	if province_id == "":
		_mat.set_shader_parameter("enabled_selection", 0.0)
		return

	var c: Color = GameState.get_mask_color_for_province(province_id)
	_mat.set_shader_parameter("selected_color", c)
	_mat.set_shader_parameter("enabled_selection", 1.0)

func _on_province_owner_changed(_province_id: String, _new_owner: String) -> void:
	# simplest approach: rebuild owner_colors array
	var owner_arr := PackedColorArray()
	for p in GameState.provinces:
		owner_arr.append(GameState.get_country_color(p["owner"]))
	_mat.set_shader_parameter("owner_colors", owner_arr)
