extends PanelContainer

@onready var country_name_label: Label = $VBoxContainer/CountryNameLabel
@onready var our_opinion_label: Label = $VBoxContainer/HSplitContainer/DiploInfoVBox/OurOpinionLabel
@onready var their_opinion_label: Label = $VBoxContainer/HSplitContainer/DiploInfoVBox/TheirOpinionLabel
@onready var invest_in_relations_button: Button = $VBoxContainer/HSplitContainer/ActionsVBox/InvestInRelationsButton

const INVEST_IN_RELATIONS_BASE_COST = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.selected_country_changed.connect(_on_selected_country_changed)
	invest_in_relations_button.pressed.connect(_on_invest_in_relations_button)

func _process(delta: float) -> void:
	if visible:
		invest_in_relations_button.disabled = true if GameState.money_by_country_id[GameState.player_tag] < INVEST_IN_RELATIONS_BASE_COST else false

func _on_selected_country_changed(country_id: String):
	print("Selected "+country_id)
	if country_id == "" || country_id==GameState.player_tag: visible = false
	else:
		visible = true
		country_name_label.text = "%s (ID: %s)"%[GameState.get_country_name_by_country_id(country_id), country_id]
		our_opinion_label.text = "Our opinion: %d"%[GameState.countries[GameState.player_tag]["diplomacy"][country_id]]
		their_opinion_label.text = "Our opinion: %d"%[GameState.countries[country_id]["diplomacy"][GameState.player_tag]]
		invest_in_relations_button.disabled = true if GameState.money_by_country_id[GameState.player_tag] < INVEST_IN_RELATIONS_BASE_COST else false

func _on_invest_in_relations_button():
	GameState.countries[GameState.player_tag]["diplomacy"][GameState.selected_country_id] = GameState.countries[GameState.player_tag]["diplomacy"][GameState.selected_country_id] + 10
	GameState.countries[GameState.selected_country_id]["diplomacy"][GameState.player_tag] = GameState.countries[GameState.selected_country_id]["diplomacy"][GameState.player_tag] + 10
	our_opinion_label.text = "Our opinion: %d"%[GameState.countries[GameState.player_tag]["diplomacy"][GameState.selected_country_id]]
	their_opinion_label.text = "Our opinion: %d"%[GameState.countries[GameState.selected_country_id]["diplomacy"][GameState.player_tag]]
	GameState.add_money(GameState.player_tag, -INVEST_IN_RELATIONS_BASE_COST)