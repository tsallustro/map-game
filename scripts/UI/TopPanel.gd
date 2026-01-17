extends PanelContainer
@onready var dateLabel: Label = $HBoxContainer/DateLabel
@onready var speedLabel: Label = $HBoxContainer/HBoxContainer2/SpeedLabel
@onready var playPauseBtn: Button = $HBoxContainer/PlayPauseButton

func _ready() -> void:
	GameState.date_changed.connect(_on_new_tick)
	GameState.speed_changed.connect(_on_speed_change)
	GameState.pause_state_changed.connect(_on_pause_toggled)
	playPauseBtn.pressed.connect(_on_pause_btn_pressed)

func _on_new_tick(new_time: Dictionary) -> void:
	var date_str = "%d %s, %d" % [
	new_time["day"],
	Utils.get_month_name_from_int(new_time["month"]),
	new_time["year"]
]

	dateLabel.text = "Date: " + date_str
	
func _on_speed_change(new_speed: int) -> void:
	speedLabel.text = "Speed: " + str(new_speed)

func _on_pause_btn_pressed() -> void:
	GameState.togglePause()

func _on_pause_toggled(isPaused: bool) -> void:
	playPauseBtn.text = "PAUSED" if isPaused else "PLAYING"
