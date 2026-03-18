extends Node
signal player_event_fired(event_data)
var rng = RandomNumberGenerator.new()
const PULSE_INTERVAL: float = 20.0
var pulse_countdown_days = PULSE_INTERVAL
var events_list: Dictionary = {}

# Eligibility cache: eligible_events[country_id] = { event_id: true }
# Only eligible events are stored; ineligible events are absent.
var eligible_events: Dictionary = {}

# Dependency indexes for incremental cache updates
var flag_dependents: Dictionary = {}       # flag_name -> [event_id, ...]
var money_dependent_events: Array = []     # event_ids with money conditions
var stability_dependent_events: Array = [] # event_ids with stability conditions
var relations_dependent_events: Array = [] # event_ids with relations conditions

var effect_handlers: Dictionary = {
	"add_money": _handle_add_money,
	"add_stability": _handle_add_stability,
	"set_global_flag": _set_global_flag,
	"clear_global_flag": _clear_global_flag,
	"change_relations": _handle_change_relations
}

var condition_handlers: Dictionary = {
	"has_global_flag": _cond_has_global_flag,
	"not_global_flag": _cond_not_global_flag,
	"money_above": _cond_money_above,
	"money_below": _cond_money_below,
	"stability_above": _cond_stability_above,
	"stability_below": _cond_stability_below,
	"relations_above": _cond_relations_above,
	"relations_below": _cond_relations_below,
	"is_country": _cond_is_country
}

func _ready() -> void:
	GameState.date_changed.connect(_on_date_changed)
	GameState.data_loaded.connect(_on_data_loaded)
	GameState.global_flag_changed.connect(_on_flag_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.stability_changed.connect(_on_stability_changed)
	GameState.relations_changed.connect(_on_relations_changed)
	rng.randomize()
	_init_events()

func _init_events() -> void:
	events_list = Utils.load_json_dict(Constants.EVENTS_FILE)
	_build_dependency_indexes()

func _on_data_loaded() -> void:
	_rebuild_all_eligibility()

# --- Dependency index building ---

func _build_dependency_indexes() -> void:
	flag_dependents.clear()
	money_dependent_events.clear()
	stability_dependent_events.clear()
	relations_dependent_events.clear()
	for event_id in events_list:
		var event_data = events_list[event_id]
		if not "conditions" in event_data:
			continue
		for condition in event_data["conditions"]:
			_index_condition(event_id, condition)

func _index_condition(event_id: String, condition: Dictionary) -> void:
	var type: String = condition["type"]
	match type:
		"has_global_flag", "not_global_flag":
			var flag_name: String = condition["value"]
			if not flag_name in flag_dependents:
				flag_dependents[flag_name] = []
			if not event_id in flag_dependents[flag_name]:
				flag_dependents[flag_name].append(event_id)
		"money_above", "money_below":
			if not event_id in money_dependent_events:
				money_dependent_events.append(event_id)
		"stability_above", "stability_below":
			if not event_id in stability_dependent_events:
				stability_dependent_events.append(event_id)
		"relations_above", "relations_below":
			if not event_id in relations_dependent_events:
				relations_dependent_events.append(event_id)
		"NOT", "OR":
			for sub_condition in condition.get("conditions", []):
				_index_condition(event_id, sub_condition)

# --- Eligibility cache ---

func _rebuild_all_eligibility() -> void:
	eligible_events.clear()
	for country_id in GameState.countries:
		eligible_events[country_id] = {}
		for event_id in events_list:
			_update_event_eligibility(event_id, country_id)

func _update_event_eligibility(event_id: String, country_id: String) -> void:
	if not country_id in eligible_events:
		eligible_events[country_id] = {}
	if _check_trigger(events_list[event_id], country_id):
		eligible_events[country_id][event_id] = true
	else:
		eligible_events[country_id].erase(event_id)

func _check_trigger(event_data: Dictionary, country_id: String) -> bool:
	if not "conditions" in event_data:
		return true
	for condition in event_data["conditions"]:
		if not _evaluate_condition(condition, country_id):
			return false
	return true

func _evaluate_condition(condition: Dictionary, country_id: String) -> bool:
	var type: String = condition["type"]
	if type == "NOT":
		for sub in condition.get("conditions", []):
			if _evaluate_condition(sub, country_id):
				return false
		return true
	if type == "OR":
		for sub in condition.get("conditions", []):
			if _evaluate_condition(sub, country_id):
				return true
		return false
	if type in condition_handlers:
		return (condition_handlers[type] as Callable).call(country_id, condition)
	push_error("EventEngine: unknown condition type '%s'" % type)
	return false

# --- Signal handlers (incremental cache updates) ---

func _on_flag_changed(flag_name: String, _is_set: bool) -> void:
	if not flag_name in flag_dependents:
		return
	for event_id in flag_dependents[flag_name]:
		for country_id in GameState.countries:
			_update_event_eligibility(event_id, country_id)

func _on_money_changed(country_id: String, _new_value: float) -> void:
	for event_id in money_dependent_events:
		_update_event_eligibility(event_id, country_id)

func _on_stability_changed(country_id: String, _new_value: int) -> void:
	for event_id in stability_dependent_events:
		_update_event_eligibility(event_id, country_id)

func _on_relations_changed(source: String, _target: String, _new_value: int) -> void:
	for event_id in relations_dependent_events:
		_update_event_eligibility(event_id, source)

# --- Pulse (date tick) ---

func _on_date_changed(_new_date: Dictionary) -> void:
	pulse_countdown_days -= 1
	if pulse_countdown_days == 0:
		for country_id in GameState.countries:
			if not country_id in eligible_events:
				continue
			for event_id in eligible_events[country_id]:
				var event_data = events_list[event_id]
				var mtth_days = max(1, event_data["MTTH"])
				var exponent = -PULSE_INTERVAL / float(mtth_days)
				var p = 1 - pow(2, exponent)
				var roll = rng.randf()
				var hit = roll < p
				print("Event %s | Hit? %s | P: %f" % [event_data["name"], hit, p])
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
			new_data["options"][i]["effects"] = []
			for j in event_data["options"][i]["effects"].size():
				var existing_effect_data = event_data["options"][i]["effects"][j]
				var new_value = _resolve_effect_vars(existing_effect_data, country_id)
				new_data["options"][i]["effects"].append(new_value)
		if "hidden_effects" in event_data["options"][i]:
			new_data["options"][i]["hidden_effects"] = []
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
			if value == "$PLAYER": new_effects[effect_param] = GameState.player_tag
	return new_effects

func process_effects(effects: Array, hidden_effects: Array, country_id: String) -> void:
	for element in effects:
		var type: String = element["type"]
		if type == "message": continue
		(effect_handlers[type] as Callable).call(country_id, element)
	for element in hidden_effects:
		var type: String = element["type"]
		(effect_handlers[type] as Callable).call(country_id, element)

# --- Effect handlers ---

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

# --- Condition handlers ---

func _cond_has_global_flag(_country_id: String, data: Dictionary) -> bool:
	return data["value"] in GameState.flags["global"]

func _cond_not_global_flag(_country_id: String, data: Dictionary) -> bool:
	return not (data["value"] in GameState.flags["global"])

func _cond_money_above(country_id: String, data: Dictionary) -> bool:
	return GameState.countries[country_id]["money"] > data["value"]

func _cond_money_below(country_id: String, data: Dictionary) -> bool:
	return GameState.countries[country_id]["money"] < data["value"]

func _cond_stability_above(country_id: String, data: Dictionary) -> bool:
	return GameState.countries[country_id]["stability"] > data["value"]

func _cond_stability_below(country_id: String, data: Dictionary) -> bool:
	return GameState.countries[country_id]["stability"] < data["value"]

func _cond_relations_above(country_id: String, data: Dictionary) -> bool:
	var source: String = data.get("source", country_id)
	var target: String = data["target"]
	return GameState.countries[source]["diplomacy"][target] > data["value"]

func _cond_relations_below(country_id: String, data: Dictionary) -> bool:
	var source: String = data.get("source", country_id)
	var target: String = data["target"]
	return GameState.countries[source]["diplomacy"][target] < data["value"]

func _cond_is_country(country_id: String, data: Dictionary) -> bool:
	return country_id == data["value"]
