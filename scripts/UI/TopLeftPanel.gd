extends PanelContainer
@onready var playerTagLabel: Label = $HBoxContainer/PlayerTagLabel
@onready var moneyLabel: Label = $HBoxContainer/MoneyLabel


var has_loaded = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.date_changed.connect(_on_new_tick)
	if !has_loaded && GameState.is_loaded:
		_initialize()

func _on_new_tick(_new_time: Dictionary) -> void:
	moneyLabel.text = "Money: %d"%[GameState.money_by_country_id[GameState.player_tag]]

func _initialize():
	playerTagLabel.text = "Player Tag: "+GameState.player_tag
	has_loaded = true
