# scenes/tournament_calendar.gd
extends Control

@onready var round_label : Label = %RoundLabel
@onready var table_rows_container : VBoxContainer = %TableRowsContainer
@onready var top_rounds_container : HBoxContainer = %TopRoundsContainer
@onready var bottom_rounds_container : HBoxContainer = %BottomRoundsContainer
@onready var play_next_btn : Button = %PlayNextBtn
@onready var simulate_btn : Button = %SimulateBtn

func _ready() -> void:
	play_next_btn.pressed.connect(_on_play_next_pressed)
	simulate_btn.pressed.connect(_on_simulate_pressed)
	_update_round_info()

func _notification(what: int) -> void:
	# Обновляем календарь при возврате на экран
	if what == NOTIFICATION_ENTER_TREE and round_label and table_rows_container:
		_update_round_info()

func _update_round_info() -> void:
	var total_rounds : int = Score.rounds.size()
	if round_label:
		round_label.text = "Тур %d из %d" % [Score.current_round + 1, total_rounds]
	if table_rows_container:
		_render_table()
	if top_rounds_container and bottom_rounds_container:
		_render_calendar()

func _render_table() -> void:
	if not table_rows_container:
		return
		
	# Очищаем таблицу
	for child in table_rows_container.get_children():
		child.queue_free()
	
	# Получаем отсортированные команды
	var sorted_teams : Array = Score.teams.duplicate()
	sorted_teams.sort_custom(_compare_teams)
	
	# Создаем строки таблицы
	for i in range(sorted_teams.size()):
		var team : Dictionary = sorted_teams[i]
		var team_name : String = String(team["name"])
		var points : int = int(team["points"])
		var goals_for : int = int(team["goals_for"])
		var goals_against : int = int(team["goals_against"])
		var diff : int = goals_for - goals_against
		
		# Создаем строку
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 5)
		row_container.custom_minimum_size = Vector2(0, 30)  # Фиксированная высота строки
		
		# Проверяем, является ли это командой игрока
		var is_player_team : bool = (team_name == Score.player_team_name)
		
		# Создаем ячейки с фиксированной шириной
		var name_cell = Label.new()
		name_cell.text = _truncate_team_name(team_name)
		name_cell.custom_minimum_size = Vector2(200, 0)
		name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_cell.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		name_cell.add_theme_font_size_override("font_size", 14)
		name_cell.add_theme_color_override("font_color", Color.WHITE)
		name_cell.clip_contents = true  # Обрезаем текст, если он не помещается
		
		var points_cell = Label.new()
		points_cell.text = str(points)
		points_cell.custom_minimum_size = Vector2(80, 0)
		points_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		points_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		points_cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		points_cell.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		points_cell.add_theme_font_size_override("font_size", 14)
		points_cell.add_theme_color_override("font_color", Color.WHITE)
		
		var gf_cell = Label.new()
		gf_cell.text = str(goals_for)
		gf_cell.custom_minimum_size = Vector2(80, 0)
		gf_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gf_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gf_cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		gf_cell.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		gf_cell.add_theme_font_size_override("font_size", 14)
		gf_cell.add_theme_color_override("font_color", Color.WHITE)
		
		var ga_cell = Label.new()
		ga_cell.text = str(goals_against)
		ga_cell.custom_minimum_size = Vector2(80, 0)
		ga_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ga_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ga_cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ga_cell.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		ga_cell.add_theme_font_size_override("font_size", 14)
		ga_cell.add_theme_color_override("font_color", Color.WHITE)
		
		var diff_cell = Label.new()
		diff_cell.text = str(diff)
		diff_cell.custom_minimum_size = Vector2(80, 0)
		diff_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diff_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		diff_cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		diff_cell.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		diff_cell.add_theme_font_size_override("font_size", 14)
		diff_cell.add_theme_color_override("font_color", Color.WHITE)
		
		# Добавляем ячейки в строку
		row_container.add_child(name_cell)
		row_container.add_child(points_cell)
		row_container.add_child(gf_cell)
		row_container.add_child(ga_cell)
		row_container.add_child(diff_cell)
		
		# Выделяем команду игрока желтым цветом
		if is_player_team:
			row_container.modulate = Color(1, 1, 0, 1.0)  # Желтый цвет
		
		# Добавляем строку в таблицу
		table_rows_container.add_child(row_container)

func _truncate_team_name(name: String) -> String:
	# Усекаем длинные названия команд до 12 символов
	if name.length() > 12:
		return name.substr(0, 10) + "..."
	return name

func _render_calendar() -> void:
	if not top_rounds_container or not bottom_rounds_container:
		return
		
	# Очищаем контейнеры
	for child in top_rounds_container.get_children():
		child.queue_free()
	for child in bottom_rounds_container.get_children():
		child.queue_free()
	
	var total_rounds : int = Score.rounds.size()
	var rounds_per_row : int = 3
	
	for round_index in range(total_rounds):
		# Создаем панель для тура
		var round_panel = Panel.new()
		round_panel.custom_minimum_size = Vector2(150, 250)
		round_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		round_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Подсвечиваем текущий тур желтым цветом
		if round_index == Score.current_round:
			round_panel.modulate = Color(1, 1, 0, 1.0)  # Желтый фон
		else:
			round_panel.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Светло-серый фон
		
		# Создаем основной контейнер для панели с центрированием
		var panel_container = CenterContainer.new()
		panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Создаем вертикальный контейнер для содержимого
		var content_container = VBoxContainer.new()
		content_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content_container.add_theme_constant_override("separation", 8)
		content_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Заголовок тура
		var round_header = Label.new()
		round_header.text = "ТУР %d" % (round_index + 1)
		round_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		round_header.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		round_header.add_theme_font_size_override("font_size", 16)
		round_header.add_theme_color_override("font_color", Color.WHITE)
		round_header.custom_minimum_size = Vector2(0, 30)
		content_container.add_child(round_header)
		
		# Разделитель
		var separator = HSeparator.new()
		separator.custom_minimum_size = Vector2(100, 2)
		content_container.add_child(separator)
		
		# Матчи тура
		var round_matches = Score.rounds[round_index]
		for match_idx in round_matches:
			var match_data : Dictionary = Score.matches[match_idx] as Dictionary
			var home_team : String = String(match_data["home"])
			var away_team : String = String(match_data["away"])
			var score_text : String = String(match_data["score"])
			var is_played : bool = bool(match_data["played"])
			
			# Создаем контейнер для матча
			var match_container = VBoxContainer.new()
			match_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			match_container.add_theme_constant_override("separation", 4)
			match_container.alignment = BoxContainer.ALIGNMENT_CENTER
			
			# Команды
			var teams_label = Label.new()
			teams_label.text = "%s\nvs\n%s" % [_truncate_team_name(home_team), _truncate_team_name(away_team)]
			teams_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			teams_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			teams_label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
			teams_label.add_theme_font_size_override("font_size", 12)
			teams_label.add_theme_color_override("font_color", Color.WHITE)
			teams_label.custom_minimum_size = Vector2(0, 50)
			teams_label.clip_contents = true
			match_container.add_child(teams_label)
			
			# Счет
			var score_label = Label.new()
			if is_played:
				score_label.text = score_text
				score_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				score_label.text = "— : —"
				score_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			score_label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
			score_label.add_theme_font_size_override("font_size", 14)
			score_label.custom_minimum_size = Vector2(0, 25)
			match_container.add_child(score_label)
			
			content_container.add_child(match_container)
		
		panel_container.add_child(content_container)
		round_panel.add_child(panel_container)
		
		# Добавляем панель в соответствующий контейнер
		if round_index < rounds_per_row:
			top_rounds_container.add_child(round_panel)
		else:
			bottom_rounds_container.add_child(round_panel)

func _compare_teams(a: Dictionary, b: Dictionary) -> bool:
	var pa : int = int(a["points"])
	var pb : int = int(b["points"])
	if pa == pb:
		var da : int = int(a["goals_for"]) - int(a["goals_against"])
		var db : int = int(b["goals_for"]) - int(b["goals_against"])
		if da == db:
			return int(a["goals_for"]) > int(b["goals_for"])
		return da > db
	return pa > pb

func _on_play_next_pressed() -> void:
	var player : String = Score.player_team_name
	var round_idxs : Array = Score.rounds[Score.current_round]
	for idx in round_idxs:
		var m : Dictionary = Score.matches[idx] as Dictionary
		var played : bool = bool(m["played"])
		var home : String = String(m["home"])
		var away : String = String(m["away"])
		if not played and (home == player or away == player):
			Score.current_match = idx
			get_tree().change_scene_to_file("res://scenes/game.tscn")
			return
	_check_advance_round()

func _on_simulate_pressed() -> void:
	var player : String = Score.player_team_name
	var round_idxs : Array = Score.rounds[Score.current_round]
	for idx in round_idxs:
		var m : Dictionary = Score.matches[idx] as Dictionary
		var played : bool = bool(m["played"])
		var home : String = String(m["home"])
		var away : String = String(m["away"])
		if not played and (home == player or away == player):
			Score.current_match = idx
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var home_goals : int = rng.randi_range(0, 4)
			var away_goals : int = rng.randi_range(0, 4)
			var goals_left : int
			var goals_right : int
			if home == player:
				goals_left = home_goals
				goals_right = away_goals
			else:
				goals_left = away_goals
				goals_right = home_goals
			# Счёт, сохраняемый в календаре, всегда отображает «голевые хозяев : голевые гостей».
			m["score"] = "%d:%d" % [home_goals, away_goals]
			m["played"] = true
			var pt : Dictionary = Score.get_team_dict(player)
			var ot_name : String
			if home == player:
				ot_name = away
			else:
				ot_name = home
			var ot : Dictionary = Score.get_team_dict(ot_name)
			pt["goals_for"] = int(pt["goals_for"]) + goals_left
			pt["goals_against"] = int(pt["goals_against"]) + goals_right
			ot["goals_for"] = int(ot["goals_for"]) + goals_right
			ot["goals_against"] = int(ot["goals_against"]) + goals_left
			var pl : int = int(pt["points"])
			var ol : int = int(ot["points"])
			if goals_left > goals_right:
				pt["points"] = pl + 3
			elif goals_left < goals_right:
				ot["points"] = ol + 3
			else:
				pt["points"] = pl + 1
				ot["points"] = ol + 1
			break
	Score.simulate_bot_matches()
	_check_advance_round()

func _check_advance_round() -> void:
	var all_played : bool = true
	var round_idxs : Array = Score.rounds[Score.current_round]
	for idx in round_idxs:
		var played : bool = bool(Score.matches[idx]["played"])
		if not played:
			all_played = false
			break
	if all_played:
		Score.current_round += 1
		if Score.current_round >= Score.rounds.size():
			get_tree().change_scene_to_file("res://scenes/final_table.tscn")
			return
	_update_round_info()
