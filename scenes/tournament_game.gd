# scenes/tournament_game.gd
extends Node

@export var half_duration : float = 15.0
@export var pause_between_halves : float = 3.0

@onready var game_node     : Node2D = get_parent() as Node2D
@onready var message_label : Label  = game_node.get_node("UI/MessageLabel") as Label

var current_half : int = 0

func _ready() -> void:
	# --- СБРОС СЧЁТА ---
	Score.left  = 0
	Score.right = 0

	current_half = 0
	_start_next_half()

func _start_next_half() -> void:
	current_half += 1
	message_label.visible = false
	game_node.call("reset_round")
	await get_tree().create_timer(half_duration).timeout
	_on_half_finished()

func _on_half_finished() -> void:
	if current_half == 1:
		message_label.text = "Второй тайм через %d сек" % int(pause_between_halves)
		message_label.visible = true
		await get_tree().create_timer(pause_between_halves).timeout
		_start_next_half()
	else:
		_finalize_match()

func _finalize_match() -> void:
	# --- определяем сторону игрока ---
	var idx  : int = Score.current_match
	var m    : Dictionary = Score.matches[idx]
	var home : String = String(m["home"])
	var away : String = String(m["away"])
	var player : String = Score.player_team_name
	var player_is_home : bool = (home == player)

	# Получаем счёт в интерфейсе (левый/правый) — это счёт игрока и ИИ.
	# В первом круге игрок выступает за домашнюю команду и его голы записываются в Score.left,
	# во втором круге игрок играет в гостях и его голы записываются в Score.right.
	var goals_left  : int = Score.left
	var goals_right : int = Score.right

	# --- определяем счёт для домашней и гостевой команды ---
	# Если игрок является домашней командой, то левый счёт соответствует хозяевам,
	# иначе хозяева — это ИИ (правый счёт), а гости — игрок (левый счёт).
	var goals_home : int
	var goals_away : int
	if player_is_home:
		goals_home = goals_left
		goals_away = goals_right
	else:
		goals_home = goals_right
		goals_away = goals_left

	# --- фиксируем результат в данные матча ---
	# В календаре турнирных матчей счёт отображается в формате «голы хозяев : голы гостей».
	m["score"]  = "%d:%d" % [goals_home, goals_away]
	m["played"] = true

	# --- обновляем статистику команд ---
	var ht : Dictionary = Score.get_team_dict(home)
	var at : Dictionary = Score.get_team_dict(away)
	# Обновляем количество забитых и пропущенных мячей для хозяев и гостей
	ht["goals_for"]     += goals_home
	ht["goals_against"] += goals_away
	at["goals_for"]     += goals_away
	at["goals_against"] += goals_home

	# Начисляем очки за победу/ничью/поражение
	if goals_home > goals_away:
		ht["points"] += 3
	elif goals_home < goals_away:
		at["points"] += 3
	else:
		ht["points"] += 1
		at["points"] += 1

	# --- корректное отображение счёта в UI ---
	# UI всегда отображает счёт с точки зрения игрока: слева — его голы, справа — голы соперника.
	if player_is_home:
		Score.left  = goals_home
		Score.right = goals_away
	else:
		Score.left  = goals_away
		Score.right = goals_home

	# --- симулируем матчи ботов и возвращаемся к календарю ---
	Score.simulate_bot_matches()
	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
