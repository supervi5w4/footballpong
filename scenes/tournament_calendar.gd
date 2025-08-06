# scenes/tournament_calendar.gd
extends Control

@onready var matches_list  : VBoxContainer = %MatchesList
@onready var play_next_btn : Button       = %PlayNextBtn

func _ready() -> void:
	_render_calendar()
	play_next_btn.pressed.connect(_on_play_next_pressed)

func _render_calendar() -> void:
	# Очищаем контейнер от старых записей
	for child in matches_list.get_children():
		child.queue_free()

	# Добавляем записи о каждом матче
	for match_data in Score.matches:
		var label : Label = Label.new()
		var result_text : String = str(match_data["score"])
		label.text = "%s — %s    %s" % [match_data["home"], match_data["away"], result_text]
		matches_list.add_child(label)

func _on_play_next_pressed() -> void:
	# Находим индекс первого несыгранного матча
	for i in range(Score.matches.size()):
		var match_data : Dictionary = Score.matches[i]
		if not match_data["played"]:
			Score.current_match = i  # запоминаем текущий матч для контроллера
			get_tree().change_scene_to_file("res://scenes/game.tscn")
			return
