# scenes/tournament_menu.gd
extends Control

@onready var team_name_input : LineEdit = %TeamNameInput
@onready var start_btn       : Button   = %StartBtn

# Список названий команд — явное указание типа массива строк
var bot_names : Array[String] = [
	"Сокол", "Торпедо", "Спартак", "Зенит",
	"Локомотив", "Шахтёр", "Динамо", "Рубин",
	"Крылья", "Нефтяник", "Урал", "Анжи"
]

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	var player_name : String = team_name_input.text.strip_edges()
	if player_name == "":
		player_name = "Игрок"

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Копия списка названий ботов — указываем тип массива
	var names_pool : Array[String] = bot_names.duplicate()
	names_pool.shuffle()

	# Явно объявляем типы строк, чтобы избежать Variant
	var bot1 : String = names_pool.pop_front()
	var bot2 : String = names_pool.pop_front()
	var bot3 : String = names_pool.pop_front()

	# Формируем массив словарей и явно указываем тип
	var teams_data : Array[Dictionary] = [
		{"name": player_name, "points": 0, "goals_for": 0, "goals_against": 0},
		{"name": bot1,       "points": 0, "goals_for": 0, "goals_against": 0},
		{"name": bot2,       "points": 0, "goals_for": 0, "goals_against": 0},
		{"name": bot3,       "points": 0, "goals_for": 0, "goals_against": 0},
	]

	Score.teams = teams_data
	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
