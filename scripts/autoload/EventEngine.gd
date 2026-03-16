extends Node
signal player_event_fired(event_data)
var rng = RandomNumberGenerator.new()
const PULSE_INTERVAL: float = 20.0
var pulse_countdown_days = PULSE_INTERVAL
var events_list: Dictionary = {}

var effect_handlers: Dictionary = {
	"add_money": _handle_add_money,
	"add_stability": _handle_add_stability,
	"set_global_flag": _set_global_flag,
	"clear_global_flag": _clear_global_flag
}

func _ready() -> void:
	GameState.date_changed.connect(_on_date_changed)
	rng.randomize()
	_init_events()


func _init_events() -> void:
	events_list = Utils.load_json_dict("res://events/test_events.json")
	
func _on_date_changed(_new_date: Dictionary) -> void:
	# Country scope events
	pulse_countdown_days = pulse_countdown_days - 1
	if (pulse_countdown_days == 0):
		for country_id in GameState.countries:
			for event_id in events_list:
				var event_data = events_list[event_id]
				var mtth_days = max(1, event_data["MTTH"])
				var exponent = - PULSE_INTERVAL / float(mtth_days)
				var p = 1 - pow(2, exponent)
				var roll = rng.randf()
				var hit = roll < p
				print("Event %s | Hit? %s | P:  %f" % [event_data["name"], hit, p])
				if hit:
					_fire_event(event_id, event_data, country_id)
					break
		pulse_countdown_days = PULSE_INTERVAL

func _fire_event(event_id: String, event_data: Dictionary, country_id: String) -> void:
	print("Firing event id %s" % [event_id])
	if country_id == GameState.player_tag:
		GameState.pause()
		emit_signal("player_event_fired", event_data)
	else:
		pass
		# process_effects(event_data["effects"],event_data["hidden_effects"],country_id)
	

func fire_event_by_id(event_id: String, country_id: String) -> void:
	_fire_event(event_id, events_list[event_id], country_id)

func process_effects(effects: Dictionary, hidden_effects: Dictionary, country_id: String) -> void:
	for effect in effects:
		if (effect != "message"):
			var value = effects[effect]
			var handler = effect_handlers[effect] as Callable
			handler.call(country_id, value)
	for hidden_effect in hidden_effects:
		var value = hidden_effects[hidden_effect]
		var handler = effect_handlers[hidden_effect] as Callable
		handler.call(country_id, value)

# Effects
func _handle_add_money(country_id: String, amount: int) -> void:
	print("EVENT HANDLER: MONEY")
	GameState.add_money(country_id, amount)
	
func _handle_add_stability(country_id: String, amount: int) -> void:
	print("EVENT HANDLER: STAB")
	GameState.add_stability(country_id, amount)

func _set_global_flag(_country_id: String, flag_name: String) -> void:
	print("EVENT HANDLER: FLAG")
	GameState.manage_global_flag(flag_name, true)

func _clear_global_flag(_country_id: String, flag_name: String) -> void:
	print("EVENT HANDLER: FLAG")
	GameState.manage_global_flag(flag_name, false)
