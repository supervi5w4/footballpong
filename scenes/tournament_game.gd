# ------------------------------------------------------------
#  scenes/tournament_game.gd  –  Логика матча в режиме турнира
#  Godot 4.4.1  |  GDScript 2.0
# ------------------------------------------------------------
extends Node

# -- Параметры длительности ―-
@export var half_duration        : float = 15.0   # секунд реального времени на тайм
@export var pause_between_halves : float = 3.0    # пауза между таймами, сек.

# -- Быстрые onready-ссылки ―-
@onready var game_node     : Node2D      = get_parent() as Node2D
@onready var ui_layer      : CanvasLayer = game_node.get_node("UI")            as CanvasLayer
@onready var message_label : Label       = ui_layer.get_node("MessageLabel")   as Label

# -- В процессе игры ―-
var scoreboard   : Control            # само табло
var current_half : int      = 0       # 1 или 2

# ========================  READY  ============================
func _ready() -> void:
		# Если запущена одиночная «быстрая» игра, этот скрипт бездействует
		if Score.matches.is_empty():
				return

		_ensure_single_scoreboard()
		_init_scoreboard_for_match()

		current_half = 0
		_start_next_half()

# ==================  СОЗДАЁМ / НАХОДИМ ТАБЛО  =================
func _ensure_single_scoreboard() -> void:
		# 1) Ищем правильный узел по имени
		scoreboard = ui_layer.get_node_or_null("Scoreboard") as Control
		if scoreboard:
				return

		# 2) Ищем любой Control-узел, чья сцена = Scoreboard.tscn
		for n in ui_layer.get_children():
				if n is Control and String(n.scene_file_path).ends_with("Scoreboard.tscn"):
						scoreboard = n
						n.name = "Scoreboard"   # возвращаем корректное имя
						return

		# 3) Не нашли – инстанцируем новую сцену
		var ps : PackedScene = preload("res://scenes/Scoreboard.tscn")
		scoreboard = ps.instantiate() as Control
		scoreboard.name = "Scoreboard"
		ui_layer.add_child(scoreboard)
		scoreboard.position = Vector2(730, 20)   # настройте под макет
		scoreboard.scale    = Vector2(0.6, 0.6)

# ==================  НАСТРОЙКА ТАБЛО  ========================
func _init_scoreboard_for_match() -> void:
		# Сбрасываем глобальный счёт
		Score.left  = 0
		Score.right = 0
		scoreboard.set_scores(0, 0)

		# Определяем, кто слева/справа на табло
		var m      : Dictionary = Score.matches[Score.current_match]
		var home   : String     = String(m["home"])
		var away   : String     = String(m["away"])
		var player : String     = Score.player_team_name

		if home == player:
				scoreboard.set_team_names(home, away)
		else:
				scoreboard.set_team_names(away, home)

		# Настройка таймера
		scoreboard.half_duration_real = half_duration
		scoreboard.half_minutes       = 45.0             # футбольных минут на тайм

# ===================  ЛОГИКА ТАЙМОВ  =========================
func _start_next_half() -> void:
		current_half += 1
		message_label.visible = false
		game_node.call("reset_round")

		if current_half == 1:
				scoreboard.start_first_half()
		else:
				scoreboard.start_second_half()

		await get_tree().create_timer(half_duration).timeout
		_on_half_finished()

func _on_half_finished() -> void:
		scoreboard.stop_timer()

		if current_half == 1:
				message_label.text = "Второй тайм через %d сек" % int(pause_between_halves)
				message_label.visible = true
				await get_tree().create_timer(pause_between_halves).timeout
				_start_next_half()
		else:
				_finalize_match()

# ===================  ЗАВЕРШЕНИЕ МАТЧА  ======================
func _finalize_match() -> void:
		# --- Кто хозяин, кто игрок? ---
		var idx      : int        = Score.current_match
		var m        : Dictionary = Score.matches[idx]
		var home     : String     = String(m["home"])
		var away     : String     = String(m["away"])
		var player   : String     = Score.player_team_name
		var player_is_home : bool = (home == player)

		# --- Счёт «слева-справа» из UI ---
		var goals_left  : int = Score.left
		var goals_right : int = Score.right

		# --- Приводим к формату «хозяева : гости» ---
		var goals_home : int
		var goals_away : int
		if player_is_home:
				goals_home = goals_left
				goals_away = goals_right
		else:
				goals_home = goals_right
				goals_away = goals_left

		# --- Записываем результат в календарь ---
		m["score"]  = "%d:%d" % [goals_home, goals_away]
		m["played"] = true

		# --- Обновляем статистику команд ---
		var ht : Dictionary = Score.get_team_dict(home)
		var at : Dictionary = Score.get_team_dict(away)
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

		# --- Сохраняем счёт для возврата в UI (слева-игрок) ---
		if player_is_home:
				Score.left  = goals_home
				Score.right = goals_away
		else:
				Score.left  = goals_away
				Score.right = goals_home

		# --- Симулируем матчи ботов и возвращаемся к календарю ---
		Score.simulate_bot_matches()
		get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")
