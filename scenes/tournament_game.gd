# scenes/tournament_game.gd
extends Node

@export var half_duration : float = 15.0
@export var pause_between_halves : float = 3.0

@onready var game_node : Node2D = get_parent()
@onready var message_label : Label = game_node.get_node("UI/MessageLabel")

var current_half : int = 0

func _ready() -> void:
	if Score.matches.is_empty():
		return
	current_half = 0
	_start_next_half()

func _start_next_half() -> void:
	current_half += 1
	message_label.visible = false
	game_node.reset_round()
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
	# Читаем итоговый счёт
	var goals_left : int = Score.left
	var goals_right : int = Score.right

	# Обновляем текущий матч
	var match_index : int = Score.current_match
	var match_data : Dictionary = Score.matches[match_index]
	match_data["score"] = "%d:%d" % [goals_left, goals_right]
	match_data["played"] = true

	# Определяем команды
	var player_team_name : String = match_data["home"]      # игрок — домашняя
	var opponent_team_name : String = match_data["away"]

	var player_team : Dictionary = get_team_dict(player_team_name)
	var opponent_team : Dictionary = get_team_dict(opponent_team_name)

	# Обновляем статистику
	player_team["goals_for"]     += goals_left
	player_team["goals_against"] += goals_right
	opponent_team["goals_for"]     += goals_right
	opponent_team["goals_against"] += goals_left

	if goals_left > goals_right:
		player_team["points"] += 3
	elif goals_left < goals_right:
		opponent_team["points"] += 3
	else:
		player_team["points"]   += 1
		opponent_team["points"] += 1

	# Сбрасываем счёт
	Score.left  = 0
	Score.right = 0

	# Возвращаемся в календарь
	get_tree().change_scene_to_file("res://scenes/tournament_calendar.tscn")

func get_team_dict(name : String) -> Dictionary:
	for team in Score.teams:
		if team["name"] == name:
			return team
	return {}
