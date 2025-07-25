# ------------------------------------------------------------
#  game.gd – менеджер раунда (вешается на корневой узел Game.tscn)
# ------------------------------------------------------------
extends Node2D

@onready var ball          := $Ball
@onready var player_paddle := $PlayerPaddle
@onready var ai_paddle     := $AiPaddle

func reset_round() -> void:
	# 1. Мяч – в центр с задержкой подачи 2 с
	if ball:
		ball.reset()                       # метод уже есть в Ball.gd

	# 2. Обе ракетки – на исходные точки
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
