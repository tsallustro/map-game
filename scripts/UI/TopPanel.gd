extends PanelContainer
@onready var dateLabel: Label = $HBoxContainer/DateLabel
@onready var speedLabel: Label = $HBoxContainer/HBoxContainer2/SpeedLabel

func _ready() -> void:
	GameState.date_changed.connect(_on_new_tick)
	GameState.speed_changed.connect(_on_speed_change)

func _on_new_tick(new_time : Dictionary)->void:
	var date_str = "%d %s, %d" % [
	new_time["day"],
	Utils.get_month_name_from_int(new_time["month"]),
	new_time["year"]
]

	dateLabel.text = "Date: "+date_str
	
func _on_speed_change(new_speed : int)->void:
	speedLabel.text = "Speed: "+str(new_speed)
