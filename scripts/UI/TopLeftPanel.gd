extends PanelContainer
@onready var playerTagLabel: Label = $HBoxContainer/PlayerTagLabel
@onready var moneyLabel: Label = $HBoxContainer/MoneyLabel


var has_loaded = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !has_loaded && GameState.is_loaded:
		_initialize()


func _initialize():
	playerTagLabel.text = "Player Tag: "+GameState.player_tag
	has_loaded = true
