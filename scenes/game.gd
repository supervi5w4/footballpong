extends Node2D

@onready var ball          := $Ball
@onready var player_paddle := $Player     # Или PlayerPaddle, если узел так называется
@onready var ai_paddle     := $AI         # Или AiPaddle, если узел так называется

func reset_round() -> void:
	if ball:
		ball.respawn()

	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
