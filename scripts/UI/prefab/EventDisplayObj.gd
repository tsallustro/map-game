extends PanelContainer
@onready var eventNameLabel: Label = $VBoxContainer/EventNameLabel
@onready var eventDescLabel: Label = $VBoxContainer/EventDescLabel
@onready var optionsContainer: VBoxContainer = $VBoxContainer/OptionsContainer

func initialize(event_data: Dictionary)->void:
	eventNameLabel.text = event_data["name"]
	eventDescLabel.text = event_data["desc"]
	var options = event_data["options"]
	for option in options:
		var btn = Button.new()
		btn.text = option["text"]
		btn.pressed.connect(func(): _on_option_selected(option))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		optionsContainer.add_child(btn)

func _on_option_selected(option_data: Dictionary)->void:
	queue_free()
	if "effects" in option_data: EventEngine.process_effects(option_data["effects"], GameState.player_tag)
	
	
