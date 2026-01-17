extends PanelContainer
@onready var p_name_label: Label = $VBoxContainer/ProvinceNameLabel
@onready var p_infra_label: Label = $VBoxContainer/InfraPanelHContainer/InfraLabel
@onready var p_terrain_label: Label = $VBoxContainer/TerrainLabel
@onready var increase_infra_btn: Button = $VBoxContainer/InfraPanelHContainer/IncreaseInfraButton

func _ready() -> void:
	GameState.data_loaded.connect(_on_data_loaded)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.province_infrastructure_changed.connect(_on_selection_changed)
	increase_infra_btn.pressed.connect(_on_infra_increase_btn_pressed)
	GameState.province_owner_changed.connect(_on_selection_changed_owner)

	if GameState.is_loaded:
		_on_data_loaded()
func _on_data_loaded() -> void:
	_on_selection_changed(GameState.selected_province_id)

func _on_selection_changed_owner(province_id: String, _new_owner_id) -> void:
		# TODO Efficiency
		_on_selection_changed(province_id)

func _on_selection_changed(province_id: String) -> void:
	if province_id == "":
		p_name_label.text = "No province selected"
		p_infra_label.text = "Infrastructure: - (Total: -)"
		p_terrain_label.text = "Terrain: -"
		return

	var province_data := GameState.get_province_by_id(province_id)
	var p_owner_id = province_data["owner"]
	p_name_label.text = _build_p_name_label_text(province_id, p_owner_id, province_data)
	p_infra_label.text = _build_p_infra_label_text(p_owner_id, province_data)
	p_terrain_label.text = _build_p_terrain_label_text(province_data)
	
func _on_infra_increase_btn_pressed() -> void:
	GameState.inc_selected_province_infrastructure()

func _build_p_name_label_text(province_id: String, owner_id: String, province_data: Dictionary) -> String:
	var p_name = province_data["name"]
	var p_owner_name = GameState.get_country_name_by_country_id(owner_id)
	return "%s (ID: %s) | %s (ID: %s)" % [p_name, province_id, p_owner_name, owner_id]

func _build_p_infra_label_text(owner_id: String, province_data: Dictionary) -> String:
	var p_infra = province_data["infrastructure"]
	var owner_total_infra = GameState.get_total_infra_by_country_id(owner_id)
	return "Infrastructure: %d (Total: %d)" % [p_infra, owner_total_infra]

func _build_p_terrain_label_text(province_data: Dictionary) -> String:
	var p_terrain = province_data["terrain"]
	return "Terrain: %s" % [p_terrain]
