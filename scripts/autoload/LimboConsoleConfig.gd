extends Node
# https://github.com/limbonaut/limbo_console

func _ready() -> void:
	LimboConsole.register_command(annex)
	LimboConsole.register_command(set_prov_owner)
	LimboConsole.register_command(save)
	LimboConsole.register_command(load)
	LimboConsole.register_command(main_menu)
	LimboConsole.register_command(tag_exists)
	LimboConsole.register_command(p_count)
	LimboConsole.register_command(cash)
	LimboConsole.register_command(event)

func annex(annexer_country_id: String, annexee_country_id: String) -> void:
	if (annexer_country_id == annexee_country_id):
		LimboConsole.error("A country cannot annex itself.")
		return
	if (!GameState.country_id_exists_or_can_exist(annexer_country_id)):
		LimboConsole.error("%s doesn't exist." % [annexer_country_id])
		return
	if (!GameState.country_id_exists(annexee_country_id)):
		LimboConsole.error("%s doesn't exist." % [annexee_country_id])
		return
	GameState.annex(annexer_country_id, annexee_country_id)
	LimboConsole.info("%s annexed %s" % [annexer_country_id, annexee_country_id])

func set_prov_owner(province_id: String, country_id: String) -> void:
	if (!GameState.province_id_exists(province_id)):
		LimboConsole.error("%s doesn't exist." % [province_id])
		return
	if (!GameState.country_id_exists_or_can_exist(country_id)):
		LimboConsole.error("%s doesn't exist." % [country_id])
		return
	GameState.set_province_owner(province_id, country_id)
	LimboConsole.info("%s now owns %s" % [country_id, province_id])

func tag_exists(country_id: String)->void:
	LimboConsole.info(str(GameState.country_id_exists(country_id)))

func p_count(country_id: String)->void:
	LimboConsole.info(str(GameState.province_count_by_country_id[country_id]))

func cash(country_id: String, amount : int)-> void:
	if(GameState.country_id_exists(country_id)): GameState.money_by_country_id[country_id] = GameState.money_by_country_id[country_id] + amount

func main_menu():
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	
func event(event_id : String):
	if event_id in EventEngine.events_list: EventEngine.fire_event_by_id(event_id, GameState.player_tag)
	else: LimboConsole.error("%s is not a valid event id" % [event_id])

func save(save_name: String) -> void:
	GameState.save_game_state(save_name)
func load(save_name: String) -> void:
	GameState.load_game_state(save_name)
