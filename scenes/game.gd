# ------------------------------------------------------------
#  game.gd – Главный скрипт игровой сцены (Game.tscn)
#  Отвечает за логику раунда, управление мячом и обновление табло
#  Требует:
#    - Менеджер счета Score (score_manager.gd, Autoload как "Score")
#    - Узлы UI/ScoreLeft и UI/ScoreRight (Label) для табло
# ------------------------------------------------------------

extends Node2D
class_name Game

@onready var ball: RigidBody2D          = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D     = $AiPaddle
@onready var score_left_label: Label        = $UI/ScoreLeft
@onready var score_right_label: Label       = $UI/ScoreRight

func _ready() -> void:
	# Сразу показываем счет на табло при запуске игры
	_update_scoreboard()
	# (Если надо: подписка на сигнал изменения счета – опционально)
	# Можно добавить сброс счета перед матчем:
	# Score.left = 0
	# Score.right = 0
	# _update_scoreboard()

func _process(_delta: float) -> void:
	# Каждый кадр обновляем табло – простой, но рабочий способ
	_update_scoreboard()

func _update_scoreboard() -> void:
	# Обновляем надписи табло с актуальным счетом
	score_left_label.text  = str(Score.left)
	score_right_label.text = str(Score.right)

func reset_round() -> void:
	# Возвращаем мяч и ракетки на стартовые позиции
	if ball:
		ball.respawn()
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()
	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
	# Сбросить табло после раунда (по желанию)
	_update_scoreboard()
