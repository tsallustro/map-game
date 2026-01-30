class_name SaveLoadController
const save_dir = "user://savegames/"

# Save format:
# Metadata (see GameState.save_game_state)
# Country data
# Non-existant Country data
# Province data

static func save_game(save_name: String, save_metadata: Dictionary, countries: Dictionary, non_existant_countries: Dictionary, provinces: Array):
	print("Saving as %s..." % [save_name])
	_create_savegame_dir_if_not_exists()
	# https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#doc-data-paths
	var path = _path_from_save_name(save_name)
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	# Set up metadata
	save_metadata["save_name"] = save_name
	
	var save_metadata_str = JSON.stringify(save_metadata)
	save_file.store_line(save_metadata_str)

	# Write country data
	var countries_str = JSON.stringify(countries)
	save_file.store_line(countries_str)
	var non_existant_countries_str = JSON.stringify(non_existant_countries)
	save_file.store_line(non_existant_countries_str)

	# Write province data
	var provinces_str = JSON.stringify(provinces)
	save_file.store_line(provinces_str)
	save_file.close()
	print("Finished saving game")


# Returns [save_name: Dictionary, countries: Dictionary, non_existant_countries: Dictionary, provinces : Array]
static func load_game(save_name: String) -> Array:
	print("===LOADING GAME DATA===")
	var path = _path_from_save_name(save_name)
	if not FileAccess.file_exists(path):
		print("Save game %s not found" % [path])
		return [ {"speed": 1, "date": - 999999999}, {}, {}, []] # Error! We don't have a save to load.

	var save_file = FileAccess.open(path, FileAccess.READ)

	# Read metadata
	var save_metadata = JSON.parse_string(save_file.get_line())

	# Read countries
	var countries = JSON.parse_string(save_file.get_line())
	var non_existant_countries = JSON.parse_string(save_file.get_line())

	# Read provinces
	var provinces = JSON.parse_string(save_file.get_line())
	
	save_file.close()

	return [save_metadata, countries, non_existant_countries, provinces]

static func read_metadata(save_name: String) -> Dictionary:
	var path = _path_from_save_name(save_name)
	if not FileAccess.file_exists(path):
		print("Save game %s not found" % [path])
		return {}
	
	var save_file = FileAccess.open(path, FileAccess.READ)

	# Read metadata
	var save_metadata = JSON.parse_string(save_file.get_line())
	save_file.close()
	return save_metadata

static func list_saves() -> Array:
	var dir = DirAccess.open(save_dir)
	var save_games = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "" && file_name.ends_with(".save"):
			save_games.append(file_name)
			file_name = dir.get_next()
		return save_games
	else:
		print("An error occurred when trying to access the path.")
		return []

static func _path_from_save_name(save_name: String) -> String:
	if save_name.ends_with(".save"): save_name = save_name.left(save_name.length() - 5)
	return "%s%s.save" % [save_dir, save_name]

static func _create_savegame_dir_if_not_exists() -> void:
	if !DirAccess.dir_exists_absolute(save_dir):
		print("Making new savegame dir")
		DirAccess.make_dir_absolute(save_dir)

static func delete_save(save_name: String) -> void:
	print("Deleting %s" % [save_name])
	DirAccess.remove_absolute(_path_from_save_name(save_name))
