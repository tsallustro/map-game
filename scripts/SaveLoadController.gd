class_name SaveLoadController

static func save_game(save_name: String, save_metadata: Dictionary, countries: Dictionary, non_existant_countries: Dictionary, provinces: Array):
	print("Saving as %s..." % [save_name])
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
	print("Finished saving game")


# Returns [save_name: String, countries: Dictionary, non_existant_countries: Dictionary, provinces : Array]
static func load_game(save_name: String) -> Array:
	var path = _path_from_save_name(save_name)
	if not FileAccess.file_exists(path):
		print("Save game %s not found" % [save_name])
		return [] # Error! We don't have a save to load.

	var save_file = FileAccess.open(path, FileAccess.READ)

	# Read metadata
	var save_metadata = JSON.parse_string(save_file.get_line())

	# Read countries
	var countries = JSON.parse_string(save_file.get_line())
	var non_existant_countries = JSON.parse_string(save_file.get_line())

	# Read provinces
	var provinces = JSON.parse_string(save_file.get_line())

	return [save_metadata, countries, non_existant_countries, provinces]

static func _path_from_save_name(save_name: String) -> String:
	return "user://%s.save" % [save_name]