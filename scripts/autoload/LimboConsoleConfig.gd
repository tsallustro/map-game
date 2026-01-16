extends Node
# https://github.com/limbonaut/limbo_console

func _ready() -> void:
	LimboConsole.register_command(annex)
	LimboConsole.register_command(set_prov_owner)
	LimboConsole.register_command(save)
	LimboConsole.register_command(load)

func annex(annexer_country_id : String, annexee_country_id : String)-> void:
	if(annexer_country_id == annexee_country_id):
		LimboConsole.error("A country cannot annex itself.")
		return
	if(!GameState.country_id_exists_or_can_exist(annexer_country_id)):
		LimboConsole.error("%s doesn't exist."%[annexer_country_id])
		return
	if(!GameState.country_id_exists(annexee_country_id)):
		LimboConsole.error("%s doesn't exist."%[annexee_country_id])
		return
	GameState.annex(annexer_country_id, annexee_country_id)
	LimboConsole.info("%s annexed %s"%[annexer_country_id, annexee_country_id]) 

func set_prov_owner(province_id : String, country_id : String)-> void:
	if(!GameState.province_id_exists(province_id)):
		LimboConsole.error("%s doesn't exist."%[province_id])
		return
	if(!GameState.country_id_exists_or_can_exist(country_id)):
		LimboConsole.error("%s doesn't exist."%[country_id])
		return
	GameState.set_province_owner(province_id, country_id)
	LimboConsole.info("%s now owns %s"%[country_id, province_id]) 

func save(save_name : String) -> void:
	GameState.save_game_state(save_name)	

func load(save_name : String) -> void:
	GameState.load_game_state(save_name)	
