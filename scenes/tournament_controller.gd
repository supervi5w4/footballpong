extends Node

# Турнирный контроллер
# Управляет турнирными матчами и их логикой

@export var half_duration: float = 15.0         # Длительность тайма (сек)
@export var pause_between_halves: float = 3.0   # Пауза между таймами (сек)

@onready var game_node: Node2D = get_parent() as Node2D
@onready var message_label: Label = game_node.get_node("UI/MessageLabel") as Label
@onready var time_scoreboard: TimeScoreboard = game_node.get_node("UI/TimeScoreboard") as TimeScoreboard

var current_half: int = 0
var ai: AiPaddle
var base_skill: float = 0.8
var match_timer: Node

const SKILL_MIN := 0.10
const SKILL_MAX := 0.99

func _ready() -> void:
	# --- Сброс счёта ---
	Score.reset_score()

	# --- Определяем позицию игрока на поле ---
	var p_paddle := game_node.get_node_or_null("PlayerPaddle")
	var a_paddle := game_node.get_node_or_null("AiPaddle")

	if p_paddle and a_paddle:
		# если игрок левее бота по оси X → он слева
		Score.player_on_left = p_paddle.global_position.x < a_paddle.global_position.x
		
		# Инициализируем флаги сторон для ракеток
		if p_paddle.has_method("set_defends_right_side"):
			p_paddle.defends_right_side = not Score.player_on_left
		if a_paddle.has_method("set_defends_right_side"):
			a_paddle.defends_right_side = Score.player_on_left
	else:
		Score.player_on_left = true  # запасной вариант

	# --- Инициализация таймера матча ---
	if time_scoreboard:
		await time_scoreboard.ready
		match_timer = time_scoreboard.get_match_timer()
		if match_timer:
			match_timer.period_changed.connect(_on_period_changed)
			match_timer.first_half_ended.connect(_on_first_half_ended)
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
	# Запускаем матч после завершения _ready всех узлов, чтобы
	# TimeScoreboard успел создать свой MatchTimer. Иначе при
	# прямом вызове _start_next_half() match_timer ещё не
	# инициализирован и игра вылетает при старте матча.
	call_deferred("_start_next_half")

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
	# Используем player_on_left для определения голов игрока и ИИ
	var player_goals: int = left if Score.player_on_left else right
	var ai_goals: int = right if Score.player_on_left else left
	var diff: int = player_goals - ai_goals
	ai.skill = clamp(base_skill + diff * 0.1, SKILL_MIN, SKILL_MAX)
	_apply_ai_tuning()

func _on_period_changed(period: int) -> void:
	"""Обработчик смены периода"""
	print("Турнир: Период изменился на ", period)
	if period == 2 and current_half == 1:
		# Второй тайм начался
		current_half = 2

func _on_first_half_ended() -> void:
	"""Обработчик окончания первого тайма"""
	print("Турнир: Первый тайм завершен")
	await _on_half_finished()

func _on_match_ended() -> void:
	"""Обработчик окончания матча"""
	print("Турнир: Матч завершен")
	_finalize_match()

func start_match() -> void:
	"""Публичный интерфейс для запуска матча"""
	_start_next_half()

func _start_next_half() -> void:
	current_half += 1
	if message_label:
		message_label.visible = false
	game_node.call("reset_round")
	
	# Запускаем матч (только таймер, не вызываем контроллер)
	if time_scoreboard:
		time_scoreboard._start_match_timer_only()
	
	print("Турнир: Матч запущен")

func _on_half_finished() -> void:
	if current_half == 1:
		# Останавливаем мяч
		var ball = game_node.get_node_or_null("Ball")
		if ball:
			ball.freeze = true
		
		if message_label:
			message_label.text = "Второй тайм через %d сек" % int(pause_between_halves)
			message_label.visible = true
		var tree = get_tree()
		if tree != null:
			await tree.create_timer(pause_between_halves).timeout
		
		# Запускаем второй тайм с перезапуском мяча
		_start_second_half()
	else:
		_finalize_match()

func _start_second_half() -> void:
	"""Запуск второго тайма с возвратом мяча в центр и сменой сторон"""
	print("Турнир: Запуск второго тайма")
	
	# Скрываем надпись о паузе между таймами
	if message_label:
		message_label.visible = false
	
	# Размораживаем мяч перед сбросом
	var ball = game_node.get_node_or_null("Ball")
	if ball:
		ball.freeze = false
	
	# Меняем стороны: игрок переходит на правую сторону
	Score.player_on_left = false
	
	# Переключаем флаги сторон для ракеток
	var player_paddle = game_node.get_node_or_null("PlayerPaddle")
	var ai_paddle = game_node.get_node_or_null("AiPaddle")
	
	if player_paddle and player_paddle.has_method("set_defends_right_side"):
		player_paddle.defends_right_side = true
	if ai_paddle and ai_paddle.has_method("set_defends_right_side"):
		ai_paddle.defends_right_side = false
	
	# Меняем стартовые позиции ракеток местами
	if player_paddle and ai_paddle:
		var temp_pos = player_paddle.start_pos
		player_paddle.start_pos = ai_paddle.start_pos
		ai_paddle.start_pos = temp_pos
	
	# Запускаем второй тайм
	if time_scoreboard:
		time_scoreboard.start_second_half()
	current_half = 2
	
	# Сбрасываем позиции ракеток на новые места
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
	
	# Мяч уже в центре после заморозки, просто запускаем его
	if ball:
		ball._teleport_to_spawn()
		ball._serve()
	
	print("Турнир: Второй тайм начался, стороны поменялись")

func _finalize_match() -> void:
	# Показываем надпись "Матч окончен" на 3 секунды
	if message_label:
		message_label.text = "Матч окончен"
		message_label.visible = true
	
	# Ждем 3 секунды
	await get_tree().create_timer(3.0).timeout
	
	# Скрываем надпись
	if message_label:
		message_label.visible = false
	
	var idx: int = Score.current_match

	if idx >= 0 and idx < Score.matches.size():
		var m: Dictionary = Score.matches[idx]
		var home: String = String(m["home"])
		var away: String = String(m["away"])
		var player_is_home: bool = Score.player_is_home

		# Используем player_on_left для определения голов игрока и ИИ
		var goals_player: int = Score.left if Score.player_on_left else Score.right
		var goals_opponent: int = Score.right if Score.player_on_left else Score.left

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
	var tree = get_tree()
	if tree == null:
		print("Турнир: get_tree() вернул null, пропускаем смену сцены")
		return
	
	# Отладочная информация
	print("Турнир: Проверяем состояние турнира:")
	print("  - current_round: ", Score.current_round)
	print("  - rounds.size(): ", Score.rounds.size())
	print("  - rounds.is_empty(): ", Score.rounds.is_empty())
	print("  - current_match: ", Score.current_match)
	
	# Проверяем, закончен ли турнир (все раунды сыграны)
	if Score.current_round >= Score.rounds.size():
		print("Турнир: Все раунды сыграны, возвращаемся в главное меню")
		tree.change_scene_to_file("res://scenes/menu.tscn")
		return

	# Симулируем матчи ботов
	Score.simulate_bot_matches()
	
	# Проверяем, нужно ли переходить к следующему раунду
	var all_played = true
	var round_idxs : Array = Score.rounds[Score.current_round]
	for round_idx in round_idxs:
		if not bool(Score.matches[round_idx]["played"]):
			all_played = false
			break
	
	if all_played:
		Score.current_round += 1
		print("Турнир: Переходим к раунду ", Score.current_round)
		
		# Проверяем, закончен ли турнир
		if Score.current_round >= Score.rounds.size():
			print("Турнир: Все раунды сыграны, переходим к финальной таблице")
			tree.change_scene_to_file("res://scenes/final_table.tscn")
			return
	
	# Переходим к календарю турнира
	print("Турнир: Продолжаем турнир, переходим к календарю")
	tree.change_scene_to_file("res://scenes/tournament_calendar.tscn")
