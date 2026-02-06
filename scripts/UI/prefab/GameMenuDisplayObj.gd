extends Control
@onready var tab_container: TabContainer = $CenterContainer/TabContainer

# Main buttons
@onready var save_menu_btn: Button = $CenterContainer/TabContainer/MainPanel/VBoxContainer/SaveMenuButton
@onready var quit_btn: Button = $CenterContainer/TabContainer/MainPanel/VBoxContainer/QuitButton
@onready var main_menu_btn: Button = $CenterContainer/TabContainer/MainPanel/VBoxContainer/MainMenuButton

# Save menu features
@onready var save_btn: Button = $CenterContainer/TabContainer/SavePanel/OrganizerVBox/ButtonsContainer/SaveButton
@onready var save_cancel_btn: Button = $CenterContainer/TabContainer/SavePanel/OrganizerVBox/ButtonsContainer/CancelButton
@onready var existing_saves: VBoxContainer = $CenterContainer/TabContainer/SavePanel/OrganizerVBox/ScrollContainer/ListExistingSavesVBox
@onready var save_name_box: LineEdit = $CenterContainer/TabContainer/SavePanel/OrganizerVBox/SaveNameContainer/SaveNameBox

func _ready() -> void:
	quit_btn.pressed.connect(func(): get_tree().quit())
	save_menu_btn.pressed.connect(_on_save_clicked)
	main_menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mainmenu.tscn"))
	save_cancel_btn.pressed.connect(_on_save_cancel)
	save_btn.pressed.connect(_handle_save)

func _on_save_clicked() -> void:
	tab_container.current_tab = 1
	var saves = SaveLoadUtils.list_saves()
	for save_name in saves:
		var formatted = SaveLoadUtils.strip_suffix(save_name)
		var button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = formatted
		button.pressed.connect(func(): save_name_box.text = formatted)
		existing_saves.add_child(button)

func _on_save_cancel() -> void:
	Utils.remove_free_all_children(existing_saves)
	tab_container.current_tab = 0

func _handle_save():
	var save_name = save_name_box.text
	GameState.save_game_state(save_name)
	_on_save_cancel()
