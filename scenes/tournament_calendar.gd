# scenes/tournament_calendar.gd
extends Control

@onready var matches_list  : VBoxContainer  = %MatchesList
@onready var play_next_btn : Button        = %PlayNextBtn
@onready var rows_container: GridContainer = %RowsContainer

const TABLE_COLUMNS := 5

func _ready() -> void:
	# Настраиваем количество колонок для таблицы
	rows_container.columns = TABLE_COLUMNS
	# Заполняем обе вкладки
	_render_calendar()
	_render_table()
	play_next_btn.pressed.connect(_on_play_next_pressed)

func _render_calendar() -> void:
	# Очищаем список матчей
	for child in matches_list.get_children():
		child.queue_free()

	# Создаём записи о матчах
	for match_data in Score.matches:
		var label : Label = Label.new()
		var result_text : String = str(match_data["score"])
		label.text = "%s — %s    %s" % [match_data["home"], match_data["away"], result_text]
		matches_list.add_child(label)

func _render_table() -> void:
	# Очищаем таблицу
	for child in rows_container.get_children():
		child.queue_free()

	# Заголовки
	var headers := ["Команда", "Очки", "Забито", "Пропущено", "Разница"]
	for h in headers:
		var header_label : Label = Label.new()
		header_label.text = h
		header_label.add_theme_color_override("font_color", Color.WHITE)
		header_label.add_theme_font_size_override("font_size", 20)
		rows_container.add_child(header_label)

	# Копируем и сортируем команды
	var sorted_teams : Array[Dictionary] = Score.teams.duplicate()
	sorted_teams.sort_custom(_compare_teams)

	# Добавляем строки с данными
	for team in sorted_teams:
		var diff : int = team["goals_for"] - team["goals_against"]
		var row := [
			team["name"],
			str(team["points"]),
			str(team["goals_for"]),
			str(team["goals_against"]),
			str(diff)
		]
		for cell_text in row:
			var cell_label : Label = Label.new()
			cell_label.text = cell_text
			rows_container.add_child(cell_label)

func _compare_teams(a : Dictionary, b : Dictionary) -> bool:
	# сортировка по очкам, затем по разнице, затем по забитым
	if a["points"] == b["points"]:
		var diff_a : int = a["goals_for"] - a["goals_against"]
		var diff_b : int = b["goals_for"] - b["goals_against"]
		if diff_a == diff_b:
			return a["goals_for"] > b["goals_for"]
		return diff_a > diff_b
	return a["points"] > b["points"]

func _on_play_next_pressed() -> void:
	# Запускаем следующий несыгранный матч
	for i in range(Score.matches.size()):
		var match_data : Dictionary = Score.matches[i]
		if not match_data["played"]:
			Score.current_match = i
			get_tree().change_scene_to_file("res://scenes/game.tscn")
			return
