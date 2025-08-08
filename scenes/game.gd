# ------------------------------------------------------------
#  game.gd – Главный скрипт игровой сцены (Game.tscn)
#  Отвечает за логику раунда, управление мячом и обновление табло
#  Требует:
#    - Менеджер счета Score (score_manager.gd, Autoload как "Score")
#    - Узлы UI/ScoreLeft и UI/ScoreRight (Label) для табло
# ------------------------------------------------------------

class_name Game
extends Node2D

@onready var ball: RigidBody2D = $Ball
@onready var player_paddle: CharacterBody2D = $PlayerPaddle
@onready var ai_paddle: CharacterBody2D = $AiPaddle
@onready var score_left_label: Label = $UI/ScoreLeft
@onready var score_right_label: Label = $UI/ScoreRight


func _ready() -> void:
	if Engine.has_singleton("Score"):
		var score: Object = Engine.get_singleton("Score")
		if score.has_signal("score_changed"):
			score.score_changed.connect(_update_scoreboard)
		_update_scoreboard()


func _update_scoreboard(_left: int = 0, _right: int = 0) -> void:
	if not Engine.has_singleton("Score"):
		return
	if not score_left_label or not score_right_label:
		return
	var score: Object = Engine.get_singleton("Score")
	score_left_label.text = str(score.left)
	score_right_label.text = str(score.right)


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
