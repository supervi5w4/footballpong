# ------------------------------------------------------------
# tournament_game.gd — Проведение матча в турнире
# Динамически настраивает ИИ по силе соперника и ходу игры
# Управляет двумя таймами и итогом
# Интегрирован с табло времени
# ------------------------------------------------------------

extends Node

@export var half_duration: float = 15.0         # Длительность тайма (сек)
@export var pause_between_halves: float = 3.0   # Пауза между таймами (сек)

@onready var game_node: Node2D = get_parent() as Node2D
@onready var message_label: Label = game_node.get_node("UI/MessageLabel") as Label
@onready var time_scoreboard: TimeScoreboard = game_node.get_node("UI/TimeScoreboard") as TimeScoreboard

var current_half: int = 0
var ai: AiPaddle
var base_skill: float = 0.8
var match_timer: MatchTimer

const SKILL_MIN := 0.10
const SKILL_MAX := 0.99

func _ready() -> void:
	# --- Сброс счёта ---
	Score.left = 0
	Score.right = 0

	# --- Инициализация таймера матча ---
	if time_scoreboard:
		match_timer = time_scoreboard.get_match_timer()
		if match_timer:
			match_timer.period_changed.connect(_on_period_changed)
			match_timer.match_ended.connect(_on_match_ended)

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
		s = clamp(s, SKILL_MIN, SKILL_MAX)
	else:
		Score.player_is_home = true
		s = clamp(s, SKILL_MIN, SKILL_MAX)

	# --- Настройка ИИ ---
	ai = game_node.get_node_or_null("AiPaddle") as AiPaddle
	if ai == null:
		push_error("AiPaddle не найден в дочерних узлах Game. Проверь путь 'AiPaddle'.")
	else:
		base_skill = s
		ai.skill = s
		_apply_ai_tuning()

	# подключаем сигнал изменения счёта (защита от двойного подключения)
	if not Score.score_changed.is_connected(_on_score_changed):
		Score.score_changed.connect(_on_score_changed)

	current_half = 0
	_start_next_half()

func _exit_tree() -> void:
	# чисто отключимся от сигналов
	if Score.score_changed.is_connected(_on_score_changed):
		Score.score_changed.disconnect(_on_score_changed)
	
	if match_timer:
		if match_timer.period_changed.is_connected(_on_period_changed):
			match_timer.period_changed.disconnect(_on_period_changed)
		if match_timer.match_ended.is_connected(_on_match_ended):
			match_timer.match_ended.disconnect(_on_match_ended)

func _apply_ai_tuning() -> void:
	if ai == null:
		return
	if ai.skill > 0.9:
		ai.behaviour_style = "aggressive"
		ai.max_bounces = 5
		ai.aggression = 0.8
	elif ai.skill > 0.8:
		ai.behaviour_style = "balanced"
		ai.max_bounces = 3
		ai.aggression = 0.5
	else:
		ai.behaviour_style = "defensive"
		ai.max_bounces = 2
		ai.aggression = 0.3

func _on_score_changed(left: int, right: int) -> void:
	if ai == null:
		return
	var player_goals: int = left if Score.player_is_home else right
	var ai_goals: int = right if Score.player_is_home else left
	var diff: int = player_goals - ai_goals
	ai.skill = clamp(base_skill + diff * 0.1, SKILL_MIN, SKILL_MAX)
	_apply_ai_tuning()

func _on_period_changed(period: int) -> void:
	"""Обработчик смены периода"""
	print("Турнир: Период изменился на ", period)
	if period == 2 and current_half == 1:
		# Второй тайм начался
		current_half = 2

func _on_match_ended() -> void:
	"""Обработчик окончания матча"""
	print("Турнир: Матч завершен")
	_finalize_match()

func _start_next_half() -> void:
	current_half += 1
	message_label.visible = false
	game_node.call("reset_round")
	
	# Используем новый таймер матча
	if match_timer:
		print("Турнир: Ожидание окончания тайма по таймеру")
		# Ждем окончания первого тайма (45 минут)
		if current_half == 1:
			# Ждем смены периода на 2
			await match_timer.period_changed
			print("Турнир: Первый тайм закончился")
		# Ждем окончания второго тайма (90 минут)
		await match_timer.match_ended
		print("Турнир: Второй тайм закончился")
		_on_half_finished()
	else:
		# Fallback на старую логику (не должно происходить)
		print("Турнир: Используется fallback таймер")
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
