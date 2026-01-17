extends Panel

# Initial Buttons
@onready var new_game_button: Button = $InitialButtons/NewGameButton
@onready var load_game_button: Button = $InitialButtons/LoadGameButton
@onready var exit_button: Button = $InitialButtons/ExitButton

# Load Game Buttons
@onready var load_game_back_button: Button = $LoadGameScreen/LoadGameBackButton
@onready var save_games_container: VBoxContainer = $LoadGameScreen/SaveGames


# Menus
@onready var initial_buttons : VBoxContainer = $InitialButtons
@onready var load_game_screen : Control = $LoadGameScreen

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_clicked)
	load_game_button.pressed.connect(_on_load_game_button_clicked)
	exit_button.pressed.connect(_on_exit_button_clicked)
	load_game_back_button.pressed.connect(_on_load_game_back_button_clicked)

func _on_new_game_button_clicked() -> void:
	GameState.load_all()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_load_game_button_clicked() -> void:
	initial_buttons.visible = false
	load_game_screen.visible = true

	var save_games = SaveLoadController.list_saves()
	print("Found %d saves: "%[save_games.size()])

	for game_name : String in save_games: 
		game_name = game_name.left(game_name.length()-5)
		var load_save_entry = Button.new()
		load_save_entry.text="Save name: %s"%[game_name]
		save_games_container.add_child(load_save_entry)
		load_save_entry.pressed.connect(func(): _load_game(game_name))
		
func _on_exit_button_clicked() -> void:
	get_tree().quit()

func _on_load_game_back_button_clicked():
	load_game_screen.visible = false
	for child in save_games_container.get_children():
		save_games_container.remove_child(child)
		child.queue_free()
	save_games_container.size = Vector2(save_games_container.size.x, 0)
	initial_buttons.visible = true

func _load_game(save_name : String):
	print("Loading "+save_name)
	GameState.load_game_state(save_name)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
