# ------------------------------------------------------------
#  tournament_calendar.gd – Турнирный календарь и таблица
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Control

# ---------- Константы для настройки ----------
const FONT_SIZE : int = 16
const PADDING : int = 20
const MIN_PANEL_SIZE : Vector2 = Vector2(190, 250)
const MAX_TEAMS_FOR_LAZY_RENDER : int = 16

# ---------- Цвета для топ-3 ----------
const GOLD_COLOR : Color = Color(1.0, 0.84, 0.0, 1.0)    # #FFD700
const SILVER_COLOR : Color = Color(0.75, 0.75, 0.75, 1.0) # #C0C0C0
const BRONZE_COLOR : Color = Color(0.8, 0.5, 0.2, 1.0)    # #CD7F32

@onready var round_label           : Label         = %RoundLabel
@onready var table_rows_container  : VBoxContainer = %TableRowsContainer
@onready var top_rounds_container  : HBoxContainer = %TopRoundsContainer
@onready var bottom_rounds_container : HBoxContainer = %BottomRoundsContainer
@onready var play_next_btn         : Button        = %PlayNextBtn
@onready var simulate_btn          : Button        = %SimulateBtn

func _ready() -> void:
	# Настройка шрифта для всего экрана
	add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
	add_theme_font_size_override("font_size", FONT_SIZE)
	
	play_next_btn.pressed.connect(_on_play_next_pressed)
	simulate_btn.pressed.connect(_on_simulate_pressed)
	_update_round_info()

func _notification(what: int) -> void:
	# Обновляем календарь при возврате на экран
	if what == NOTIFICATION_ENTER_TREE and round_label and table_rows_container:
		_update_round_info()

# --------------------- Обновление экрана ---------------------

func _update_round_info() -> void:
	var total_rounds : int = Score.rounds.size()
	print("Календарь: Обновляем информацию о раунде:")
	print("  - current_round: ", Score.current_round)
	print("  - total_rounds: ", total_rounds)
	
	if round_label:
		round_label.text = "Тур %d из %d" % [Score.current_round + 1, total_rounds]
	if table_rows_container:
		_render_table()
	if top_rounds_container and bottom_rounds_container:
		_render_calendar()

# --------------------- Таблица команд ------------------------

func _render_table() -> void:
	if not table_rows_container:
		return
	
	# Очищаем таблицу
	for child in table_rows_container.get_children():
		child.queue_free()
	
	# Получаем отсортированные команды
	var sorted_teams : Array = Score.teams.duplicate()
	sorted_teams.sort_custom(_compare_teams)
	
	# Создаем строки
	for i in range(sorted_teams.size()):
		var team : Dictionary = sorted_teams[i]
		var team_name   : String = String(team["name"])
		var points      : int    = int(team["points"])
		var goals_for   : int    = int(team["goals_for"])
		var goals_against : int  = int(team["goals_against"])
		var diff        : int    = goals_for - goals_against
		
		# Контейнер строки
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 5)
		row_container.custom_minimum_size = Vector2(0, 30)
		
		var is_player_team : bool = (team_name == Score.player_team_name)
		
		# Определяем цвет для топ-3
		var text_color : Color = Color.WHITE
		if i == 0:
			text_color = GOLD_COLOR
		elif i == 1:
			text_color = SILVER_COLOR
		elif i == 2:
			text_color = BRONZE_COLOR
		
		# Ячейки
		var name_cell = _make_label(_truncate_team_name(team_name), 200, 14, text_color)
		var points_cell = _make_label(str(points), 80, 14, text_color)
		var gf_cell = _make_label(str(goals_for), 80, 14, text_color)
		var ga_cell = _make_label(str(goals_against), 80, 14, text_color)
		var diff_cell = _make_label(str(diff), 80, 14, text_color)
		
		row_container.add_child(name_cell)
		row_container.add_child(points_cell)
		row_container.add_child(gf_cell)
		row_container.add_child(ga_cell)
		row_container.add_child(diff_cell)
		
		if is_player_team:
			row_container.modulate = Color(1, 1, 0, 1)  # выделяем жёлтым
		
		table_rows_container.add_child(row_container)

func _make_label(text: String, width: int, font_size: int, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.clip_contents = true
	return label

func _truncate_team_name(name: String) -> String:
	if name.length() > 12:
		return name.substr(0, 10) + "..."
	return name

# --------------------- Календарь туров ------------------------

func _render_calendar() -> void:
	if not top_rounds_container or not bottom_rounds_container:
		return
	
	for child in top_rounds_container.get_children():
		child.queue_free()
	for child in bottom_rounds_container.get_children():
		child.queue_free()
	
	var total_rounds : int = Score.rounds.size()
	var rounds_per_row : int = 3
	
	for round_index in range(total_rounds):
		var round_panel = Panel.new()
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)  # прозрачный фон
		style.border_color = Color(1, 1, 1, 1)  # белая рамка
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2

		round_panel.add_theme_stylebox_override("panel", style)
		
		round_panel.custom_minimum_size = MIN_PANEL_SIZE
		
		round_panel.modulate = (
			Color(1, 1, 0, 1) if round_index == Score.current_round
			else Color(0.8, 0.8, 0.8, 1)
		)
		
		var content_container = CenterContainer.new()
		content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var inner_container = VBoxContainer.new()
		inner_container.alignment = BoxContainer.ALIGNMENT_CENTER
		inner_container.add_theme_constant_override("separation", 8)
		
		# Заголовок тура
		var round_header = Label.new()
		round_header.text = "ТУР %d" % (round_index + 1)
		round_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		round_header.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
		round_header.add_theme_font_size_override("font_size", 16)
		round_header.add_theme_color_override("font_color", Color.WHITE)
		round_header.custom_minimum_size = Vector2(0, 30)
		inner_container.add_child(round_header)
		
		# Разделитель
		var separator = HSeparator.new()
		separator.custom_minimum_size = Vector2(100, 2)
		inner_container.add_child(separator)
		
		# Матчи тура
		var round_matches = Score.rounds[round_index]
		for match_idx in round_matches:
			var match_data : Dictionary = Score.matches[match_idx]
			var home_team : String = String(match_data["home"])
			var away_team : String = String(match_data["away"])
			var score_text : String = String(match_data["score"])
			var is_played : bool = bool(match_data["played"])
			
			var match_container = VBoxContainer.new()
			match_container.alignment = BoxContainer.ALIGNMENT_CENTER
			match_container.add_theme_constant_override("separation", 4)
			
			var teams_label = Label.new()
			teams_label.text = "%s\nvs\n%s" % [_truncate_team_name(home_team), _truncate_team_name(away_team)]
			teams_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			teams_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			teams_label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
			teams_label.add_theme_font_size_override("font_size", 12)
			teams_label.add_theme_color_override("font_color", Color.WHITE)
			teams_label.custom_minimum_size = Vector2(0, 50)
			match_container.add_child(teams_label)
			
			var score_label = Label.new()
			score_label.text = score_text if is_played else "— : —"
			score_label.add_theme_color_override("font_color", Color.GREEN if is_played else Color.LIGHT_GRAY)
			score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			score_label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
			score_label.add_theme_font_size_override("font_size", 14)
			score_label.custom_minimum_size = Vector2(0, 25)
			match_container.add_child(score_label)
			
			inner_container.add_child(match_container)
		
		content_container.add_child(inner_container)
		round_panel.add_child(content_container)
		
		if round_index < rounds_per_row:
			top_rounds_container.add_child(round_panel)
		else:
			bottom_rounds_container.add_child(round_panel)

# --------------------- Сортировка -----------------------------

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

# --------------------- Управление ------------------------------

func _on_play_next_pressed() -> void:
	var player : String = Score.player_team_name
	var round_idxs : Array = Score.rounds[Score.current_round]
	print("Календарь: Ищем следующий матч игрока в раунде ", Score.current_round)
	
	for match_idx in round_idxs:
		var m : Dictionary = Score.matches[match_idx]
		if not bool(m["played"]) and (m["home"] == player or m["away"] == player):
			print("Календарь: Найден матч ", match_idx, " - ", m["home"], " vs ", m["away"])
			Score.current_match = match_idx
			get_tree().change_scene_to_file("res://scenes/game.tscn")
			return
	
	print("Календарь: Матчи игрока в текущем раунде не найдены, проверяем переход к следующему раунду")
	_check_advance_round()

func _on_simulate_pressed() -> void:
	var player : String = Score.player_team_name
	var round_idxs : Array = Score.rounds[Score.current_round]
	for match_idx in round_idxs:
		var m : Dictionary = Score.matches[match_idx]
		if not bool(m["played"]) and (m["home"] == player or m["away"] == player):
			Score.current_match = match_idx
			
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			var home_goals = rng.randi_range(0, 4)
			var away_goals = rng.randi_range(0, 4)
			
			var goals_left = home_goals if m["home"] == player else away_goals
			var goals_right = away_goals if m["home"] == player else home_goals
			
			m["score"] = "%d:%d" % [home_goals, away_goals]
			m["played"] = true
			
			var pt = Score.get_team_dict(player)
			var ot_name = m["away"] if m["home"] == player else m["home"]
			var ot = Score.get_team_dict(ot_name)
			
			pt["goals_for"] = int(pt["goals_for"]) + goals_left
			pt["goals_against"] = int(pt["goals_against"]) + goals_right
			ot["goals_for"] = int(ot["goals_for"]) + goals_right
			ot["goals_against"] = int(ot["goals_against"]) + goals_left
			
			if goals_left > goals_right:
				pt["points"] = int(pt["points"]) + 3
			elif goals_left < goals_right:
				ot["points"] = int(ot["points"]) + 3
			else:
				pt["points"] = int(pt["points"]) + 1
				ot["points"] = int(ot["points"]) + 1
			break
	
	Score.simulate_bot_matches()
	_check_advance_round()

func _check_advance_round() -> void:
	var all_played = true
	var round_idxs : Array = Score.rounds[Score.current_round]
	print("Календарь: Проверяем завершение раунда ", Score.current_round)
	
	for round_idx in round_idxs:
		if not bool(Score.matches[round_idx]["played"]):
			all_played = false
			print("Календарь: Матч ", round_idx, " еще не сыгран")
			break
	
	if all_played:
		print("Календарь: Все матчи раунда сыграны, переходим к раунду ", Score.current_round + 1)
		Score.current_round += 1
		if Score.current_round >= Score.rounds.size():
			print("Календарь: Турнир завершен, переходим к финальной таблице")
			get_tree().change_scene_to_file("res://scenes/final_table.tscn")
			return
	
	_update_round_info()
