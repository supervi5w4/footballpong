# scenes/game.gd вЂ“ corrected root controller for Football Pong
#
# Handles resetting the ball and paddles after each goal.  The original
# implementation referenced child nodes by names that did not match the
# scene, which caused the paddles to never reset.  This version searches
# for both the legacy and current node names to remain robust across
# variations of the scene.
extends Node2D
class_name Game

@onready var ball: RigidBody2D = $Ball
var player_paddle: CharacterBody2D
var ai_paddle: CharacterBody2D

func _ready() -> void:
	# Locate the player paddle.  Some scenes may name it "PlayerPaddle"
	# while older versions may use "Player".  Use the first that exists.
	player_paddle = get_node_or_null("PlayerPaddle")
	if player_paddle == null:
		player_paddle = get_node_or_null("Player")

	# Locate the AI paddle.  Similarly handle both naming conventions.
	ai_paddle = get_node_or_null("AiPaddle")
	if ai_paddle == null:
		ai_paddle = get_node_or_null("AI")

func reset_round() -> void:
	# Restart the ball.
	if ball and ball.has_method("respawn"):
		ball.respawn()

	# Reset the player paddle to its starting position if the method exists.
	if player_paddle and player_paddle.has_method("reset_position"):
		player_paddle.reset_position()

	# Reset the AI paddle as well.
	if ai_paddle and ai_paddle.has_method("reset_position"):
		ai_paddle.reset_position()
