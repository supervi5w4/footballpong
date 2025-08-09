# scenes/tournament_menu.gd
extends Control

@onready var team_name_input: LineEdit = %TeamNameInput
@onready var start_btn: Button = %StartBtn

# ► Пул 30 клубов с коэффициентом силы (0.10..1.00)
const BOT_POOL: Array[Dictionary] = [
	{"name":"Спартак", "strength": 1.00},
	{"name":"ЦСКА", "strength": 0.97},
	{"name":"Зенит", "strength": 0.94},
	{"name":"Динамо Москва", "strength": 0.91},
	{"name":"Динамо Киев", "strength": 0.88},
	{"name":"Шахтёр", "strength": 0.84},
	{"name":"Торпедо", "strength": 0.81},
	{"name":"Локомотив", "strength": 0.78},
	{"name":"Динамо Минск", "strength": 0.75},
	{"name":"Днепр", "strength": 0.72},
	{"name":"Нефтчи", "strength": 0.69},
	{"name":"Кайрат", "strength": 0.66},
	{"name":"Черноморец", "strength": 0.63},
	{"name":"Арарат", "strength": 0.60},
	{"name":"Пахтакор", "strength": 0.57},
	{"name":"Заря", "strength": 0.53},
	{"name":"Металлист", "strength": 0.50},
	{"name":"Ростсельмаш", "strength": 0.47},
	{"name":"Кубань", "strength": 0.44},
	{"name":"Уралмаш", "strength": 0.41},
	{"name":"СКА Ростов", "strength": 0.38},
	{"name":"Таврия", "strength": 0.35},
	{"name":"Жальгирис", "strength": 0.32},
	{"name":"Крылья Советов", "strength": 0.29},
	{"name":"Сокол", "strength": 0.26},
	{"name":"Анжи", "strength": 0.22},
	{"name":"Судостроитель", "strength": 0.19},
	{"name":"Нистру", "strength": 0.16},
	{"name":"Спартак Орёл", "strength": 0.13},
	{"name":"Металлург Зап.", "strength": 0.10},
]

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)

# Добавляем боту поля статистики (очки и голы), нормализуем strength
func _augment_bot(bot: Dictionary) -> Dictionary:
	var d := bot.duplicate(true)
	d["strength"] = clamp(float(d.get("strength", 0.8)), 0.1, 1.0)
	d["points"] = 0
	d["goals_for"] = 0
	d["goals_against"] = 0
	return d

func _on_start_pressed() -> void:
	var player_name := team_name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Игрок"

	# Не допускаем совпадение имени игрока с ботами (редкий кейс, но пусть будет)
	var existing_names := BOT_POOL.map(func(b): return String(b["name"]))
	if existing_names.has(player_name):
		player_name += " ★"

	# 1) копия пула, перемешиваем
	var pool := BOT_POOL.duplicate(true)
	pool.shuffle()

	# 2) страховка: проверим, что ботов хватает
	if pool.size() < 3:
		push_error("Недостаточно ботов в пуле (нужно >= 3).")
		return

	# 3) берём первых 3 ботов
	var b1: Dictionary = pool.pop_front()
	var b2: Dictionary = pool.pop_front()
	var b3: Dictionary = pool.pop_front()

	# 4) формируем teams_data
	var teams_data: Array[Dictionary] = [
		{"name": player_name, "strength": 0.90, "points": 0, "goals_for": 0, "goals_against": 0},
		_augment_bot(b1),
		_augment_bot(b2),
		_augment_bot(b3),
	]

	# 5) записываем в Score и генерируем календарь
	Score.teams = teams_data
	Score.player_team_name = player_name
	Score.generate_matches()

	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
