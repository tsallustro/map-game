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

	var p := GameState.get_province_by_id(province_id)
	label.text = "%s\nOwner: %s\nID: %s" % [p["name"], p["owner"], province_id]
