extends PanelContainer

@onready var label: Label = $Label

var provinces := {} # filled by Main

func set_provinces(p: Dictionary) -> void:
	provinces = p

func bind_map(map_layer: Node) -> void:
	map_layer.province_clicked.connect(_on_province_clicked)

func _on_province_clicked(key: String) -> void:
	if provinces.has(key):
		var p = provinces[key]
		label.text = "%s\nOwner: %s\nKey: %s" % [p.name, p.owner, key]
	else:
		label.text = "Unknown province\nKey: %s" % key
