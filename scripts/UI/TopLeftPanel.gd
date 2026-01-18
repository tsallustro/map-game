extends PanelContainer
@onready var playerTagLabel: Label = $HBoxContainer/PlayerTagLabel
@onready var moneyLabel: Label = $HBoxContainer/MoneyLabel


var has_loaded = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.date_changed.connect(_on_new_tick)
	GameState.force_reload_TL_panel.connect(_force_reload)
	if !has_loaded && GameState.is_loaded:
		_initialize()

func _force_reload():
	_on_new_tick(GameState.current_date)

func _on_new_tick(_new_time: Dictionary) -> void:
	var money_amount = GameState.money_by_country_id[GameState.player_tag]
	moneyLabel.text = "Money: %d"%[money_amount]

func _initialize():
	playerTagLabel.text = "Player Tag: "+GameState.player_tag
	has_loaded = true
