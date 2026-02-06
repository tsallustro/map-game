extends Panel

# Initial Buttons
@onready var new_game_button: Button = $InitialButtons/NewGameButton
@onready var load_game_button: Button = $InitialButtons/LoadGameButton
@onready var exit_button: Button = $InitialButtons/ExitButton

# Load Game Screen
@onready var load_game_back_button: Button = $LoadGameScreen/LoadGameBackButton
@onready var save_games_container: VBoxContainer = $LoadGameScreen/SaveGamesScroll/SaveGames

# New Game Screen
@onready var new_game_back_button: Button = $NewGameScreen/NewGameBackButton
@onready var country_select_container: VBoxContainer = $NewGameScreen/CountrySelectScroll/CountrySelect

# New Game Sort Buttons
@onready var name_sort_button: Button = $NewGameScreen/HBoxContainer/NameSortButton
@onready var prov_sort_button: Button = $NewGameScreen/HBoxContainer/ProvinceSortButton
@onready var infra_sort_button: Button = $NewGameScreen/HBoxContainer/InfraSortButton

# Menus
@onready var initial_buttons: VBoxContainer = $InitialButtons
@onready var load_game_screen: Control = $LoadGameScreen
@onready var new_game_screen: Control = $NewGameScreen

# New Game Sort Logic
enum SortMode {NAME, PROV, INFRA, UNSORTED}
var sort_mode_to_buttons = {}
var sort_mode = SortMode.UNSORTED
var country_select_entries = []
var up_triangle = "▲"
var down_triangle = "▼"
var sort_is_down = true

func _ready() -> void:
	sort_mode_to_buttons = {SortMode.NAME: {"btn": name_sort_button, "text": "Name"},
	SortMode.PROV: {"btn": prov_sort_button, "text": "Provinces"},
	SortMode.INFRA: {"btn": infra_sort_button, "text": "Infra"}}

	new_game_button.pressed.connect(_on_new_game_button_clicked)
	load_game_button.pressed.connect(_on_load_game_button_clicked)
	exit_button.pressed.connect(_on_exit_button_clicked)
	load_game_back_button.pressed.connect(_on_load_game_back_button_clicked)
	new_game_back_button.pressed.connect(_on_new_game_back_button_clicked)

	name_sort_button.pressed.connect(func(): _sort_new_game_countries(SortMode.NAME))
	prov_sort_button.pressed.connect(func(): _sort_new_game_countries(SortMode.PROV))
	infra_sort_button.pressed.connect(func(): _sort_new_game_countries(SortMode.INFRA))

func _on_new_game_button_clicked() -> void:
	GameState.load_all()
	initial_buttons.visible = false
	new_game_screen.visible = true
	_build_country_select_entries()
	_sort_new_game_countries(SortMode.NAME)
	for entry in country_select_entries:
		country_select_container.add_child(entry["obj"])


func _build_country_select_entries() -> void:
	for country_id in GameState.countries:
		var cont := HBoxContainer.new()
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.alignment = BoxContainer.ALIGNMENT_CENTER

		var country_data = GameState.countries[country_id]
		var country_name = country_data["name"]
		var province_count = GameState.province_count_by_country_id[country_id]
		var infra = GameState.total_infra_by_country_id[country_id]
		# Color rectangle
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(120, 80)
		var color = Utils.rgb_to_color(country_data["color"])
		color_rect.color = color
		cont.add_child(color_rect)

		# Name and data
		var country_select_entry = Button.new()
		country_select_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		country_select_entry.text = "%s | Total provinces: %d | Total infra: %d" % [country_name, province_count, infra]
		cont.add_child(country_select_entry)
		country_select_entry.pressed.connect(func(): _new_game(country_id))

		country_select_entries.append({"name": country_name, "provinces": province_count, "infra": infra, "obj": cont})

func _sort_new_game_countries(new_sort: SortMode) -> void:
	if new_sort == sort_mode:
		country_select_entries.reverse()
		sort_is_down = !sort_is_down
		var button: Button = sort_mode_to_buttons[new_sort]["btn"]
		var button_text: String = sort_mode_to_buttons[new_sort]["text"]
		button.text = "%s %s" % [button_text, down_triangle if sort_is_down else up_triangle]
	else:
		match new_sort:
			SortMode.NAME:
				country_select_entries.sort_custom(func(a, b): return a["name"] < b["name"])
			SortMode.PROV:
				country_select_entries.sort_custom(func(a, b): return a["provinces"] > b["provinces"])
			SortMode.INFRA:
				country_select_entries.sort_custom(func(a, b): return a["infra"] > b["infra"])
		
		# Set new sort button
		var new_button: Button = sort_mode_to_buttons[new_sort]["btn"]
		var new_button_text: String = sort_mode_to_buttons[new_sort]["text"]
		new_button.text = "%s %s" % [new_button_text, down_triangle]
		sort_is_down = true

		# Reset old sort button
		if sort_mode != SortMode.UNSORTED:
			var old_button: Button = sort_mode_to_buttons[sort_mode]["btn"]
			old_button.text = sort_mode_to_buttons[sort_mode]["text"]
		
		sort_mode = new_sort
	for child in country_select_container.get_children():
		country_select_container.remove_child(child)
	for entry in country_select_entries:
		country_select_container.add_child(entry["obj"])

func _on_load_game_button_clicked() -> void:
	initial_buttons.visible = false
	load_game_screen.visible = true

	var save_games = SaveLoadController.list_saves()
	print("Found %d saves" % [save_games.size()])

	for game_name: String in save_games:
		var save_metadata = SaveLoadController.read_metadata(game_name)
		var cont := HBoxContainer.new()
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.alignment = BoxContainer.ALIGNMENT_CENTER

		# Color rectangle
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(120, 80)
		var color = Utils.rgb_to_color(save_metadata["player_color"])
		color_rect.color = color
		cont.add_child(color_rect)

		# Name and data
		var load_game_btn = Button.new()
		load_game_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var country_name = save_metadata["player_name_pretty"]
		var in_game_date = Utils.pretty_date_from_unix(save_metadata["game_date"])
		var save_date = Utils.pretty_date_from_unix(save_metadata["save_date"])
		load_game_btn.text = "%s %s | Last saved: %s" % [country_name, in_game_date, save_date]
		cont.add_child(load_game_btn)
		load_game_btn.pressed.connect(func(): _load_game(game_name))

		# Delete save button
		var delete_button = Button.new()
		delete_button.text = "Delete"
		delete_button.pressed.connect(func(): _on_delete_save_clicked(game_name, cont))
		cont.add_child(delete_button)
		save_games_container.add_child(cont)
		
func _on_exit_button_clicked() -> void:
	get_tree().quit()

func _on_delete_save_clicked(save_name: String, container_obj) -> void:
	SaveLoadController.delete_save(save_name)
	save_games_container.remove_child(container_obj)

func _on_load_game_back_button_clicked():
	load_game_screen.visible = false
	for child in save_games_container.get_children():
		save_games_container.remove_child(child)
		child.queue_free()
	save_games_container.size = Vector2(save_games_container.size.x, 0)
	initial_buttons.visible = true

func _on_new_game_back_button_clicked():
	new_game_screen.visible = false
	for child in country_select_container.get_children():
		country_select_container.remove_child(child)
		child.queue_free()
	country_select_container.size = Vector2(country_select_container.size.x, 0)
	initial_buttons.visible = true

func _load_game(save_name: String):
	print("Loading " + save_name)
	(func(): GameState.load_game_state(save_name)).call_deferred()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
func _new_game(country_id: String):
	GameState.player_tag = country_id
	get_tree().change_scene_to_file("res://scenes/main.tscn")
