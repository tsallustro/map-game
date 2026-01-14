extends Control

@onready var cam: Camera2D = $MapLayer/Camera2D
@onready var map_sprite: Sprite2D = $MapLayer/MapSprite

@onready var province_btn: Button = $UI/ViewButtons/HBoxContainer/ProvinceViewButton
@onready var owner_btn: Button = $UI/ViewButtons/HBoxContainer/OwnerViewButton

func _ready() -> void:
	# Buttons -> GameState
	province_btn.pressed.connect(_on_province_view_pressed)
	owner_btn.pressed.connect(_on_owner_view_pressed)

	# Keep button state in sync even if something else changes view mode later
	GameState.view_mode_changed.connect(_on_view_mode_changed)

	# Default is OWNER (GameState already defaults to this, but set explicitly)
	GameState.set_view_mode(GameState.ViewMode.OWNER)
	_on_view_mode_changed(GameState.view_mode)

	# Center camera on the map texture
	var tex: Texture2D = map_sprite.texture
	if tex != null:
		var tex_size: Vector2 = tex.get_size()
		cam.position = tex_size / 2.0

func _on_province_view_pressed() -> void:
	GameState.set_view_mode(GameState.ViewMode.PROVINCE)

func _on_owner_view_pressed() -> void:
	GameState.set_view_mode(GameState.ViewMode.OWNER)

func _on_view_mode_changed(mode: int) -> void:
	# Visual feedback: disable active button
	owner_btn.disabled = (mode == GameState.ViewMode.OWNER)
	province_btn.disabled = (mode == GameState.ViewMode.PROVINCE)
	print("Set view mode: "+str(mode))
