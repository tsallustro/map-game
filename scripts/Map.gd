extends Node2D
signal province_clicked(key: String)

@export var mask_texture: Texture2D
@onready var map_sprite: Sprite2D = $MapSprite

var _mat: ShaderMaterial
var _mask_image: Image

func _ready() -> void:
	_mask_image = mask_texture.get_image()
	_mat = map_sprite.material as ShaderMaterial

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * mb.position
			var key: String = _province_key_at_world(world_pos)
			if key != "":
				emit_signal("province_clicked", key)
				_set_selected_key(key)
			else:
				_clear_selection()

		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_pan((event as InputEventMouseMotion).relative)

func _province_key_at_world(world_pos: Vector2) -> String:
	var x := int(floor(world_pos.x))
	var y := int(floor(world_pos.y))

	if x < 0 or y < 0 or x >= _mask_image.get_width() or y >= _mask_image.get_height():
		return ""

	var c: Color = _mask_image.get_pixel(x, y)

	# black = water / none
	if c.r == 0.0 and c.g == 0.0 and c.b == 0.0:
		return ""

	var r := int(round(c.r * 255.0))
	var g := int(round(c.g * 255.0))
	var b := int(round(c.b * 255.0))
	return "%d,%d,%d" % [r, g, b]

func _zoom(factor: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d() as Camera2D
	cam.zoom *= Vector2(factor, factor)
	cam.zoom.x = clamp(cam.zoom.x, 0.2, 5.0)
	cam.zoom.y = clamp(cam.zoom.y, 0.2, 5.0)

func _pan(delta: Vector2) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d() as Camera2D
	cam.position -= delta * cam.zoom.x
	
func _set_selected_key(key: String) -> void:
	var parts := key.split(",")
	if parts.size() != 3:
		return

	var r := int(parts[0])
	var g := int(parts[1])
	var b := int(parts[2])

	_mat.set_shader_parameter("selected_color", Color(r / 255.0, g / 255.0, b / 255.0, 1.0))
	_mat.set_shader_parameter("enabled_selection", 1.0)

func _clear_selection() -> void:
	_mat.set_shader_parameter("enabled_selection", 0.0)
