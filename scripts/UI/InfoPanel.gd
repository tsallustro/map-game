extends PanelContainer
@onready var label: Label = $Label

func _ready() -> void:
	GameState.data_loaded.connect(_on_data_loaded)
	GameState.selection_changed.connect(_on_selection_changed)

func _on_data_loaded() -> void:
	_on_selection_changed(GameState.selected_province_id)

func _on_selection_changed(province_id: String) -> void:
	if province_id == "":
		label.text = "No province selected"
		return

	var province_data := GameState.get_province_by_id(province_id)
	label.text = _build_label_text(province_id, province_data)

func _build_label_text(province_id: String, province_data: Dictionary) -> String:
	var p_name = province_data["name"]
	var p_owner_tag = province_data["owner"]
	var p_owner_name = GameState.get_country_name_by_country_id(province_data["owner"])
	var p_terrain = province_data["terrain"]
	var p_infra = province_data["infrastructure"]
	var owner_total_infra = GameState.get_total_infra_by_country_id(p_owner_tag)
	return "%s\nID: %s\nOwner: %s (%s)\nTerrain: %s\nInfra %d (Total: %d)" % [p_name, province_id, p_owner_name, p_owner_tag, p_terrain, p_infra, owner_total_infra]
