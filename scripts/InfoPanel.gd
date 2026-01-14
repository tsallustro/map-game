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
	return "%s\nID: %s\nOwner: %s\nTerrain: %s" % [province_data["name"], province_id, province_data["owner"], province_data["terrain"]]
