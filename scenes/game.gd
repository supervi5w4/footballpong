# scenes/game.gd
extends Node2D

@onready var ball          := $Ball
@onready var player_paddle := $PlayerPaddle   # Имя узла слева!
@onready var ai_paddle     := $AiPaddle       # Имя узла справа!

var scoreboard : Control

func _ready() -> void:
		# Создаём и добавляем табло
		var scoreboard_scene : PackedScene = preload("res://scenes/Scoreboard.tscn")
		scoreboard = scoreboard_scene.instantiate() as Control
		# Добавляем в CanvasLayer UI
		$UI.add_child(scoreboard)
		# Опционально позиционируем и масштабируем табло
		scoreboard.position = Vector2(730, 20)     # смещение от левого верхнего угла (подберите при необходимости)
		scoreboard.scale    = Vector2(0.6, 0.6)    # масштаб (подберите при необходимости)

		# Прячем старые элементы счёта
		if $UI.has_node("ScoreboardBG"):
				$UI.get_node("ScoreboardBG").visible = false
		if $UI.has_node("ScoreLeft"):
				$UI.get_node("ScoreLeft").visible = false
		if $UI.has_node("ScoreRight"):
				$UI.get_node("ScoreRight").visible = false

		# Быстрая игра (нет данных турнира) — инициализируем табло сами
		if Score.matches.is_empty():
				scoreboard.set_team_names("Игрок", "ИИ")
				scoreboard.set_scores(Score.left, Score.right)
				# Настройка времени тайма: 15 секунд реального времени → 45 футбольных минут
				scoreboard.half_duration_real = 15.0
				scoreboard.half_minutes       = 45.0
				scoreboard.start_first_half()
				# Подключаем сигнал, чтобы автоматически запускать второй тайм и останавливать после окончания
				scoreboard.half_finished.connect(_on_quick_half_finished)

func _on_quick_half_finished(half : int) -> void:
		if half == 1:
				# Запускаем второй тайм сразу
				scoreboard.start_second_half()
		elif half == 2:
				# Полный матч окончен — останавливаем таймер
				scoreboard.stop_timer()

func reset_round() -> void:
		if ball:
				ball.respawn()

		if player_paddle and player_paddle.has_method("reset_position"):
				player_paddle.reset_position()

		if ai_paddle and ai_paddle.has_method("reset_position"):
				ai_paddle.reset_position()
