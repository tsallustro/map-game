extends Control

@onready var map_layer := $MapLayer
@onready var info_panel := $UI/InfoPanel
@onready var cam := $MapLayer/Camera2D
@onready var map_sprite := $MapLayer/MapSprite
@onready var province_btn: Button = $UI/ViewButtons/HBoxContainer/ProvinceViewButton
@onready var owner_btn: Button = $UI/ViewButtons/HBoxContainer/OwnerViewButton

enum ViewMode { OWNER, PROVINCE }
var view_mode: ViewMode = ViewMode.OWNER

var owner_palette := {
	"A": Color(0.85, 0.10, 0.10, 1.0),
	"B": Color(0.10, 0.70, 0.20, 1.0),
	"C": Color(0.10, 0.35, 0.85, 1.0),
	"D": Color(0.75, 0.55, 0.10, 1.0),
}

func _ready() -> void:
	# Connect UI
	info_panel.bind_map(map_layer)
	province_btn.pressed.connect(_on_province_view_pressed)
	owner_btn.pressed.connect(_on_owner_view_pressed)
	_set_view_mode(ViewMode.OWNER) # default
	# Minimal “database”: replace keys with your actual RGBs later.
	var provinces := {
		"235,42,255": {"name": "Dark Purple Province", "owner": "A"},
		"9,6,255": {"name": "Blue Province", "owner": "A"},
		"255,240,4": {"name": "Yellow Province", "owner": "B"},
		"255,83,8": {"name": "Orange Province", "owner": "C"},
		"11,255,170": {"name": "Green Province", "owner": "C"},
		"3,255,238": {"name": "Teal Province", "owner": "D"},
		"255,131,107": {"name": "Maroon Province", "owner": "D"},
		"255,123,206": {"name": "Light Purple Province", "owner": "D"},
	}
	info_panel.set_provinces(provinces)
	
	# Center camera on the map texture
	var tex: Texture2D = map_sprite.texture
	if tex:
		var tex_size: Vector2 = tex.get_size()
		cam.position = tex_size / 2.0
	
	var mat := map_sprite.material as ShaderMaterial

	# IMPORTANT: keep a stable order (so arrays line up)
	var keys := provinces.keys()
	keys.sort() # stable for now; later you’ll want an explicit ID order

	var prov_arr := PackedColorArray()
	var owner_arr := PackedColorArray()

	for k in keys:
		var prov_col := _key_to_color(k)
		prov_arr.append(prov_col)

		var owner_id: String = provinces[k]["owner"]
		var owner_col: Color = owner_palette.get(owner_id, Color(1,1,1,1))
		owner_arr.append(owner_col)

	# Set shader arrays
	mat.set_shader_parameter("prov_colors", prov_arr)
	mat.set_shader_parameter("owner_colors", owner_arr)

	# Default view = owner
	mat.set_shader_parameter("view_mode", 0)
func _on_province_view_pressed() -> void:
	_set_view_mode(ViewMode.PROVINCE)

func _on_owner_view_pressed() -> void:
	_set_view_mode(ViewMode.OWNER)

func _set_view_mode(mode: ViewMode) -> void:
	view_mode = mode

	# Simple visual feedback for now:
	owner_btn.disabled = (mode == ViewMode.OWNER)
	province_btn.disabled = (mode == ViewMode.PROVINCE)

	# Optional: print to confirm it's working
	print("View mode:", "OWNER" if mode == ViewMode.OWNER else "PROVINCE")
	var mat := map_sprite.material as ShaderMaterial
	mat.set_shader_parameter("view_mode", 0 if mode == ViewMode.OWNER else 1)
	
	
func _key_to_color(key: String) -> Color:
	var parts := key.split(",")
	var r := float(parts[0]) / 255.0
	var g := float(parts[1]) / 255.0
	var b := float(parts[2]) / 255.0
	return Color(r, g, b, 1.0)
	
