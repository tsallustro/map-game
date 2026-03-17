extends PanelContainer
@onready var eventNameLabel: Label = $VBoxContainer/EventNameLabel
@onready var eventDescLabel: Label = $VBoxContainer/EventDescLabel
@onready var optionsContainer: VBoxContainer = $VBoxContainer/OptionsContainer

var effect_names_pretty: Dictionary = {
	"add_money": "%+d money",
	"add_stability": "%+d stability",
	"set_global_flag": "Flag %s is set",
	"clear_global_flag": "Flag %s is cleared",
	"message": "%s"
}

func initialize(event_data: Dictionary) -> void:
	eventNameLabel.text = event_data["name"]
	eventDescLabel.text = event_data["desc"]
	var options = event_data["options"]
	for option in options:
		var btn = Button.new()
		btn.text = option["text"]
		btn.pressed.connect(func(): _on_option_selected(option))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if "effects" in option: btn.tooltip_text = _generate_tooltip_text(option["effects"])
		optionsContainer.add_child(btn)

func _generate_tooltip_text(effects_dict: Dictionary) -> String:
	var generated_tooltip_text: String = ""
	for effect in effects_dict:
		generated_tooltip_text = generated_tooltip_text + effect_names_pretty[effect] % [effects_dict[effect]] + "\n"
	return generated_tooltip_text

func _on_option_selected(option_data: Dictionary) -> void:
	queue_free()
	var effects: Dictionary = option_data["effects"] if "effects" in option_data else {}
	var hidden_effects: Dictionary = option_data["hidden_effects"] if "hidden_effects" in option_data else {}
	EventEngine.process_effects(effects, hidden_effects, GameState.player_tag)
