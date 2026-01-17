extends PanelContainer
@onready var dateLabel: Label = $DateTimeHBoxContainer/DateLabel
@onready var speedLabel: Label = $DateTimeHBoxContainer/SpeedHBoxContainer/SpeedLabel
@onready var playPauseBtn: Button = $DateTimeHBoxContainer/SpeedHBoxContainer/PlayPauseButton

# Speed Buttons
@onready var speed_up_btn: Button = $DateTimeHBoxContainer/SpeedHBoxContainer/SpeedUpButton
@onready var speed_down_btn: Button = $DateTimeHBoxContainer/SpeedHBoxContainer/SpeedDownButton

var has_loaded = false

func _ready() -> void:
	GameState.date_changed.connect(_on_new_tick)
	GameState.speed_changed.connect(_on_speed_change)
	GameState.pause_state_changed.connect(_on_pause_toggled)
	playPauseBtn.pressed.connect(_on_pause_btn_pressed)
	speed_up_btn.pressed.connect(_on_speed_up_pressed)
	speed_down_btn.pressed.connect(_on_speed_down_pressed)
	if !has_loaded && GameState.is_loaded:
		_initialize()

func _initialize():
	_on_new_tick(GameState.current_date)
	_on_speed_change(GameState.speed)
	_on_pause_toggled(GameState.isPaused)
	has_loaded = true

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

func _on_speed_up_pressed() -> void:
	GameState.inc_speed()

func _on_speed_down_pressed() -> void:
	GameState.dec_speed()
