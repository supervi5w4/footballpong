# ------------------------------------------------------------
# tournament_game.gd — Проведение матча в турнире
# Динамически настраивает ИИ по силе соперника
# Управляет двумя таймами и результатами
# ------------------------------------------------------------

extends Node

@export var half_duration: float = 15.0                # Длительность тайма (сек)
@export var pause_between_halves: float = 3.0          # Пауза между таймами (сек)

@onready var game_node: Node2D = get_parent() as Node2D
@onready var message_label: Label = game_node.get_node("UI/MessageLabel") as Label

var current_half: int = 0

func _ready() -> void:
	# --- Сброс счёта ---
	Score.left = 0
	Score.right = 0

	# --- Инициализация силы соперника ---
	var idx: int = Score.current_match
	var s: float = 0.8
	if idx >= 0 and idx < Score.matches.size():
		var m: Dictionary = Score.matches[idx]
		var home: String = String(m["home"])
		Score.player_is_home = (home == Score.player_team_name)

		var player_is_home: bool = Score.player_is_home
		var opponent_name: String = String(m["away"]) if player_is_home else String(m["home"])
		var opponent: Dictionary = Score.get_team_dict(opponent_name)

		s = float(opponent.get("strength", 0.8))
		s = clamp(s, 0.6, 0.99)
	else:
		Score.player_is_home = true  # по умолчанию
		s = clamp(s, 0.6, 0.99)

	# --- Настройка ИИ ---
	var ai = game_node.get_node("AiPaddle") as AiPaddle
	ai.skill = s
	if s > 0.9:
		ai.behaviour_style = "aggressive"
	elif s > 0.8:
		ai.behaviour_style = "balanced"
	else:
		ai.behaviour_style = "defensive"

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
	var idx: int = Score.current_match

	if idx >= 0 and idx < Score.matches.size():
		var m: Dictionary = Score.matches[idx]
		var home: String = String(m["home"])
		var away: String = String(m["away"])
		var player_is_home: bool = Score.player_is_home

		var goals_player: int = Score.left
		var goals_opponent: int = Score.right

		var goals_home: int
		var goals_away: int
		if player_is_home:
			goals_home = goals_player
			goals_away = goals_opponent
		else:
			goals_home = goals_opponent
			goals_away = goals_player

		# --- Сохраняем результат матча ---
		m["score"] = "%d:%d" % [goals_home, goals_away]
		m["played"] = true

		# --- Обновляем статистику команд ---
		var ht: Dictionary = Score.get_team_dict(home)
		var at: Dictionary = Score.get_team_dict(away)
		ht["goals_for"]     += goals_home
		ht["goals_against"] += goals_away
		at["goals_for"]     += goals_away
		at["goals_against"] += goals_home

		if goals_home > goals_away:
			ht["points"] += 3
		elif goals_home < goals_away:
			at["points"] += 3
		else:
			ht["points"] += 1
			at["points"] += 1

	# --- Финализация: выход в меню или следующий турнирный матч ---
	if Score.rounds.is_empty():
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	Score.simulate_bot_matches()
	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
