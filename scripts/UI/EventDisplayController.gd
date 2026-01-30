extends Control
@export var eventDisplayPrefab: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventEngine.player_event_fired.connect(_on_event_fire)


func _on_event_fire(event_data: Dictionary) -> void:
	var display = eventDisplayPrefab.instantiate()
	add_child(display)
	display.initialize(event_data)
