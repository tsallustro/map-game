extends PanelContainer

@onready var country_name_label: Label = $VBoxContainer/CountryNameLabel
@onready var our_opinion_label: Label = $VBoxContainer/HSplitContainer/DiploInfoVBox/OurOpinionLabel
@onready var their_opinion_label: Label = $VBoxContainer/HSplitContainer/DiploInfoVBox/TheirOpinionLabel
@onready var invest_in_relations_button: Button = $VBoxContainer/HSplitContainer/ActionsVBox/InvestInRelationsButton
@onready var alliance_button: Button = $VBoxContainer/HSplitContainer/ActionsVBox/AllianceButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.selected_country_changed.connect(_on_selected_country_changed)
	GameState.force_diplomacy_panel_refresh.connect(_on_force_refresh)
	invest_in_relations_button.pressed.connect(_on_invest_in_relations_button)
	alliance_button.pressed.connect(_on_alliance_button)

func _process(_delta: float) -> void:
		invest_in_relations_button.disabled = !_improve_relations_button_enabled()

func _on_force_refresh(selected_country_id: String):
	_on_selected_country_changed(selected_country_id)

func _on_selected_country_changed(selected_country_id: String):
	print("Selected "+selected_country_id)
	if selected_country_id == "" || selected_country_id==GameState.player_tag: visible = false
	else:
		visible = true
		country_name_label.text = "%s (ID: %s)"%[GameState.get_country_name_by_country_id(selected_country_id), selected_country_id]
		our_opinion_label.text = "Our opinion: %d"%[GameState.countries[GameState.player_tag]["diplomacy"][selected_country_id]]
		their_opinion_label.text = "Their opinion: %d"%[GameState.countries[selected_country_id]["diplomacy"][GameState.player_tag]]
		invest_in_relations_button.disabled = true if GameState.money_by_country_id[GameState.player_tag] < Constants.INVEST_IN_RELATIONS_BASE_COST else false
		invest_in_relations_button.tooltip_text = "Invest 100 money to raise bilateral relations by 10."
		
		if !GameState.is_allied(GameState.player_tag, GameState.selected_country_id):
			alliance_button.text = "Form alliance"
			alliance_button.tooltip_text = "Form an alliance and raise bilateral relations by 20."
		else:
			alliance_button.text = "Break alliance"
			alliance_button.tooltip_text = "Break our alliance. This will harm their opinion of us by -20."

func _on_alliance_button():
	var was_allied = GameState.is_allied(GameState.player_tag, GameState.selected_country_id)
	
	if was_allied: GameState.change_relations(GameState.selected_country_id, GameState.player_tag, -20)
	else: GameState.change_bilateral_relations(GameState.selected_country_id, GameState.player_tag, 20)

	GameState.manage_alliance(GameState.player_tag, GameState.selected_country_id, !was_allied)

	
func _on_invest_in_relations_button():
	GameState.change_bilateral_relations(GameState.player_tag, GameState.selected_country_id, 10)
	our_opinion_label.text = "Our opinion: %d"%[GameState.countries[GameState.player_tag]["diplomacy"][GameState.selected_country_id]]
	their_opinion_label.text = "Their opinion: %d"%[GameState.countries[GameState.selected_country_id]["diplomacy"][GameState.player_tag]]
	GameState.add_money(GameState.player_tag, -Constants.INVEST_IN_RELATIONS_BASE_COST)

func _improve_relations_button_enabled()->bool:
	return GameState.selected_country_id != "" && (GameState.money_by_country_id[GameState.player_tag] >= Constants.INVEST_IN_RELATIONS_BASE_COST) && GameState.get_selected_country_relation_of_player() < Constants.RELATIONS_MAX
