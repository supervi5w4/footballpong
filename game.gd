extends Node2D

@onready var ball          := $Ball
@onready var player_paddle := $PlayerPaddle   # Имя узла слева!
@onready var ai_paddle     := $AiPaddle       # Имя узла справа!

func reset_round() -> void:
	if ball:
		ball.respawn()

	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
