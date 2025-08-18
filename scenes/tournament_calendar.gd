# scenes/tournament_calendar.gd
extends Control

@onready var round_label    : Label         = %RoundLabel
@onready var matches_list   : VBoxContainer = %MatchesList
@onready var play_next_btn  : Button        = %PlayNextBtn
@onready var simulate_btn   : Button        = %SimulateBtn
@onready var rows_container : GridContainer = %RowsContainer

const TABLE_COLUMNS : int = 5

func _ready() -> void:
	rows_container.columns = TABLE_COLUMNS
	play_next_btn.pressed.connect(_on_play_next_pressed)
	simulate_btn.pressed.connect(_on_simulate_pressed)
	_update_round_info()

func _notification(what: int) -> void:
	# Обновляем календарь при возврате на экран
	if what == NOTIFICATION_ENTER_TREE and round_label and matches_list and rows_container:
		_update_round_info()

func _update_round_info() -> void:
	var total_rounds : int = Score.rounds.size()
	if round_label:
		round_label.text = "Тур %d из %d" % [Score.current_round + 1, total_rounds]
	if matches_list:
		_render_calendar()  # Перерисовываем календарь с обновленной подсветкой
	if rows_container:
		_render_table()

func _render_calendar() -> void:
	if not matches_list:
		return
		
	# Очищаем список матчей
	for child in matches_list.get_children():
		child.queue_free()
	
	# Создаем основной контейнер для разделения на две части
	var main_container = VBoxContainer.new()
	main_container.custom_minimum_size = Vector2(0, 600)  # Увеличиваем высоту для лучшего отображения
	main_container.add_theme_constant_override("separation", 30)  # Увеличиваем отступ между рядами
	
	# Создаем контейнер для верхних 3 туров
	var top_container = HBoxContainer.new()
	top_container.custom_minimum_size = Vector2(0, 250)
	top_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_theme_constant_override("separation", 15)  # Увеличиваем отступ между панелями
	
	# Создаем контейнер для нижних 3 туров
	var bottom_container = HBoxContainer.new()
	bottom_container.custom_minimum_size = Vector2(0, 250)
	bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_container.add_theme_constant_override("separation", 15)  # Увеличиваем отступ между панелями
	
	# Разбиваем турнир на 6 туров (3 вверху, 3 внизу)
	var total_rounds = Score.rounds.size()
	var rounds_per_row = 3
	
	for round_index in range(total_rounds):
		# Создаем панель для тура
		var round_panel = Panel.new()
		round_panel.custom_minimum_size = Vector2(120, 220)  # Увеличиваем размеры панели
		round_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Подсвечиваем текущий тур жёлтым цветом (непрозрачный)
		if round_index == Score.current_round:
			round_panel.modulate = Color(1, 1, 0, 1.0)  # Жёлтый фон без прозрачности
		else:
			round_panel.modulate = Color(0.8, 0.8, 0.8, 1.0)  # Светло-серый фон без прозрачности
		
		# Создаем контейнер для содержимого тура
		var round_container = VBoxContainer.new()
		round_container.custom_minimum_size = Vector2(0, 220)
		round_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		round_container.add_theme_constant_override("separation", 5)  # Отступ между элементами
		
		# Заголовок тура
		var round_header = Label.new()
		round_header.text = "Тур %d" % (round_index + 1)
		round_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_header.add_theme_font_size_override("font_size", 14)
		round_header.add_theme_color_override("font_color", Color.BLACK)
		round_container.add_child(round_header)
		
		# Матчи тура
		var round_idxs = Score.rounds[round_index]
		for idx in round_idxs:
			var m = Score.matches[idx] as Dictionary
			var home = String(m["home"])
			var away = String(m["away"])
			var score_text = String(m["score"])
			var match_label = Label.new()
			match_label.text = "%s — %s\n%s" % [home, away, score_text]
			match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			match_label.add_theme_font_size_override("font_size", 10)
			match_label.add_theme_color_override("font_color", Color.BLACK)
			round_container.add_child(match_label)
		
		# Добавляем контейнер в панель
		round_panel.add_child(round_container)
		
		# Добавляем панель в соответствующий контейнер (верхний или нижний)
		if round_index < rounds_per_row:
			top_container.add_child(round_panel)
		else:
			bottom_container.add_child(round_panel)
	
	# Добавляем оба контейнера в основной
	main_container.add_child(top_container)
	main_container.add_child(bottom_container)
	
	# Добавляем основной контейнер в список
	matches_list.add_child(main_container)

func _render_table() -> void:
	if not rows_container:
		return
		
	for child in rows_container.get_children():
		child.queue_free()
	
	# Заголовки таблицы
	var headers : Array = ["Команда", "Очки", "Забито", "Пропущено", "Разница"]
	for h in headers:
		var hl : Label = Label.new()
		hl.text = String(h)
		hl.add_theme_font_size_override("font_size", 12)
		hl.add_theme_color_override("font_color", Color.BLACK)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows_container.add_child(hl)
	
	# Данные команд
	var sorted : Array = Score.teams.duplicate()
	sorted.sort_custom(_compare_teams)
	for t in sorted:
		@warning_ignore("shadowed_variable_base_class")
		var name : String = String(t["name"])
		var points : int = int(t["points"])
		var gf : int = int(t["goals_for"])
		var ga : int = int(t["goals_against"])
		var diff : int = gf - ga
		var row : Array = [name, str(points), str(gf), str(ga), str(diff)]
		for v in row:
			var cell : Label = Label.new()
			cell.text = v
			cell.add_theme_font_size_override("font_size", 10)
			cell.add_theme_color_override("font_color", Color.BLACK)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rows_container.add_child(cell)

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
