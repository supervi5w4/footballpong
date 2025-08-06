# scenes/tournament_menu.gd
extends Control

@onready var team_name_input: LineEdit = %TeamNameInput
@onready var start_btn: Button = %StartBtn

# ► Пул 30 советских клубов + коэффициент силы
var bot_pool: Array = [
	{"name":"Спартак", "strength": 1.00},
	{"name":"ЦСКА", "strength": 0.95},
	{"name":"Зенит", "strength": 0.92},
	{"name":"Динамо Москва", "strength": 0.91},
	{"name":"Динамо Киев", "strength": 0.91},
	{"name":"Шахтёр", "strength": 0.90},
	{"name":"Торпедо", "strength": 0.88},
	{"name":"Локомотив", "strength": 0.87},
	{"name":"Динамо Минск", "strength": 0.85},
	{"name":"Днепр", "strength": 0.85},
	{"name":"Нефтчи", "strength": 0.84},
	{"name":"Кайрат", "strength": 0.83},
	{"name":"Черноморец", "strength": 0.82},
	{"name":"Арарат", "strength": 0.82},
	{"name":"Пахтакор", "strength": 0.81},
	{"name":"Заря", "strength": 0.80},
	{"name":"Металлист", "strength": 0.80},
	{"name":"Ростсельмаш", "strength": 0.79},
	{"name":"Кубань", "strength": 0.78},
	{"name":"Уралмаш", "strength": 0.78},
	{"name":"СКА Ростов", "strength": 0.77},
	{"name":"Таврия", "strength": 0.77},
	{"name":"Жальгирис", "strength": 0.76},
	{"name":"Крылья Советов", "strength": 0.76},
	{"name":"Сокол", "strength": 0.75},
	{"name":"Анжи", "strength": 0.75},
	{"name":"Судостроитель", "strength": 0.74},
	{"name":"Нистру", "strength": 0.74},
	{"name":"Спартак Орёл", "strength": 0.73},
	{"name":"Металлург Зап.", "strength": 0.72},
]

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)

# Добавляем к боту поля статистики (очки и голы)
func _augment_bot(bot: Dictionary) -> Dictionary:
	var d := bot.duplicate(true)
	d["points"] = 0
	d["goals_for"] = 0
	d["goals_against"] = 0
	return d

func _on_start_pressed() -> void:
	var player_name := team_name_input.text.strip_edges()
	if player_name == "":
		player_name = "Игрок"

	# 1) копия пула, перемешиваем
	var pool := bot_pool.duplicate()
	pool.shuffle()

	# 2) берём первых 3 ботов
	var b1: Dictionary = pool.pop_front()
	var b2: Dictionary = pool.pop_front()
	var b3: Dictionary = pool.pop_front()

	# 3) формируем teams_data
	var teams_data: Array = [
		{"name": player_name, "strength": 0.90, "points": 0, "goals_for": 0, "goals_against": 0},
		_augment_bot(b1),
		_augment_bot(b2),
		_augment_bot(b3),
	]

	Score.teams = teams_data
	Score.player_team_name = player_name
	Score.generate_matches()

	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
