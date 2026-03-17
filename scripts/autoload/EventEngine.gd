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
	"clear_global_flag": _clear_global_flag,
	"change_relations": _handle_change_relations
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
		var new_event_data = _resolve_all_vars(event_data, country_id)
		emit_signal("player_event_fired", new_event_data)
	else:
		pass
		# process_effects(event_data["effects"],event_data["hidden_effects"],country_id)
	

func fire_event_by_id(event_id: String, country_id: String) -> void:
	_fire_event(event_id, events_list[event_id], country_id)

func _resolve_all_vars(event_data: Dictionary, country_id: String) -> Dictionary:
	# TODO: process vars in event name, desc
	var new_data = event_data.duplicate(true)
	for i in event_data["options"].size():
		if "effects" in event_data["options"][i]:
			new_data["options"][i]["effects"]=[]
			for j in event_data["options"][i]["effects"].size():
				var existing_effect_data = event_data["options"][i]["effects"][j]
				var new_value = _resolve_effect_vars(existing_effect_data, country_id)
				new_data["options"][i]["effects"].append(new_value)
		if "hidden_effects" in event_data["options"][i]:
			new_data["options"][i]["hidden_effects"]=[]
			for k in event_data["options"][i]["hidden_effects"].size():
				var existing_hidden_effect_data = event_data["options"][i]["hidden_effects"][k]
				var new_value = _resolve_effect_vars(existing_hidden_effect_data, country_id)
				new_data["options"][i]["hidden_effects"].append(new_value)
	return new_data

func _resolve_effect_vars(effects_dict: Dictionary, country_id: String) -> Dictionary:
	var new_effects = effects_dict.duplicate(true)
	for effect_param in effects_dict:
		var value = effects_dict[effect_param]
		if value is String:
			if value == "$THIS": new_effects[effect_param] = country_id
			if value == "$PLAYER": new_effects[effect_param] =  GameState.player_tag
	return new_effects


func process_effects(effects: Array, hidden_effects: Array, country_id: String) -> void:
	for element in effects:
		var type: String = element["type"]
		if type == "message": continue
		(effect_handlers[type] as Callable).call(country_id, element)
	for element in hidden_effects:
		var type: String = element["type"]
		(effect_handlers[type] as Callable).call(country_id, element)

# Effects
func _handle_add_money(country_id: String, data: Dictionary) -> void:
	print("EVENT HANDLER: MONEY")
	GameState.add_money(country_id if "target" not in data else data["target"], data["value"])
	
func _handle_add_stability(country_id: String, data: Dictionary) -> void:
	print("EVENT HANDLER: STAB")
	GameState.add_stability(country_id if "target" not in data else data["target"], data["value"])

func _set_global_flag(_country_id: String, data: Dictionary) -> void:
	print("EVENT HANDLER: FLAG")
	GameState.manage_global_flag(data["value"], true)

func _clear_global_flag(_country_id: String, data: Dictionary) -> void:
	print("EVENT HANDLER: FLAG")
	GameState.manage_global_flag(data["value"], false)

func _handle_change_relations(_country_id: String, data: Dictionary) -> void:
	print("EVENT HANDLER: CHANGE RELATIONS")
	GameState.change_relations(data["source"], data["target"], data["value"])
	GameState.force_diplomacy_panel_refresh.emit(GameState.selected_country_id)
