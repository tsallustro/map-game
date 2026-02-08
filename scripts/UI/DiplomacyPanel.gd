extends PanelContainer

@onready var country_name_label: Label = $CountryNameLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.selected_country_changed.connect(_on_selected_country_changed)


func _on_selected_country_changed(country_id: String):
	print("Selected "+country_id)
	if country_id == "": visible = false
	else:
		visible = true
		country_name_label.text = "%s (ID: %s)"%[GameState.get_country_name_by_country_id(country_id), country_id]
