extends Node
signal event_fired(event_data)
var rng = RandomNumberGenerator.new()
const PULSE_INTERVAL : float = 20.0
var pulse_countdown_days = PULSE_INTERVAL
var events_list : Dictionary = {}
func _ready() -> void:
	GameState.date_changed.connect(_on_date_changed)
	rng.randomize()
	_init_events()


func _init_events() -> void:
	events_list = Utils.load_json_dict("res://events/events.json")

func _on_date_changed(_new_date: Dictionary)->void:
	pulse_countdown_days = pulse_countdown_days - 1
	if(pulse_countdown_days == 0):
		for event_id in events_list:
			var event_data = events_list[event_id]
			var mtth_days = max(1,event_data["MTTH"])
			var exponent = -PULSE_INTERVAL / float(mtth_days)
			var p = 1-pow(2, exponent)
			var roll = rng.randf()
			var hit = roll < p
			print("Event %s | Hit? %s | P:  %f"%[event_data["name"], hit, p])
			if hit:
				_fire_event(event_id,event_data)
				break
		pulse_countdown_days = PULSE_INTERVAL


func _fire_event(event_id : String, event_data: Dictionary)->void:
	GameState.pause()
	print("Firing event id %s"%[event_id])
	emit_signal("event_fired", event_data)

func fire_event_by_id(event_id : String)->void:
	_fire_event(event_id, events_list[event_id])
