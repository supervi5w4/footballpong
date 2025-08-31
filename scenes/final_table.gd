# ------------------------------------------------------------
#  final_table.gd – Финальная таблица турнира
#  Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Control

# ---------- Константы для настройки ----------
const FONT_SIZE : int = 16
const PADDING : int = 20
const MIN_PANEL_SIZE : Vector2 = Vector2(800, 600)
const MAX_TEAMS_FOR_LAZY_RENDER : int = 16

# ---------- Цвета для топ-3 ----------
const GOLD_COLOR : Color = Color(1.0, 0.84, 0.0, 1.0)    # #FFD700
const SILVER_COLOR : Color = Color(0.75, 0.75, 0.75, 1.0) # #C0C0C0
const BRONZE_COLOR : Color = Color(0.8, 0.5, 0.2, 1.0)    # #CD7F32

# ---------- ссылки на UI-узлы ----------
@onready var main_container : CenterContainer = %MainContainer
@onready var panel_container : PanelContainer = %PanelContainer
@onready var scroll_container : ScrollContainer = %ScrollContainer
@onready var content_container : VBoxContainer = %ContentContainer
@onready var title_label : Label = %TitleLabel
@onready var table_container : GridContainer = %TableContainer
@onready var place_label : Label = %PlaceLabel
@onready var menu_btn : Button = %MenuBtn
@onready var replay_btn : Button = %ReplayBtn

const COLS : int = 5   # Команда | Очки | GF | GA | Δ

# ---------- старт ----------
func _ready() -> void:
	# Настройка шрифта для всего экрана
	add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
	add_theme_font_size_override("font_size", FONT_SIZE)
	
	# Настройка фона и панели
	($Bg as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	
	%PanelContainer.set_anchors_preset(Control.PRESET_CENTER)
	%PanelContainer.custom_minimum_size = Vector2(1200, 700)
	
	%ScrollContainer.set_anchors_preset(Control.PRESET_FULL_RECT)
	%ScrollContainer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	%ScrollContainer.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	%ContentContainer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Настройка таблицы
	table_container.columns = COLS
	table_container.add_theme_constant_override("h_separation", PADDING)
	table_container.add_theme_constant_override("v_separation", PADDING)
	
	# Настройка кнопки
	%ReplayBtn.text = tr("Начать турнир заново")
	if not %ReplayBtn.pressed.is_connected(_on_replay_pressed):
		%ReplayBtn.pressed.connect(_on_replay_pressed)
	
	# Подключение кнопки меню
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Отрисовка
	_render_table()
	_show_player_place()

# ---------- отрисовка таблицы ----------
func _render_table() -> void:
	# очистка старого содержимого
	for child in table_container.get_children():
		child.queue_free()

	# Заголовки
	var headers : Array = [tr("Команда"), tr("Очки"), tr("Забито"), tr("Пропущено"), tr("Разница")]
	for header_text in headers:
		var header : Label = _create_label(header_text, true)
		table_container.add_child(header)

	# Копия и сортировка команд
	var sorted : Array = Score.teams.duplicate(true)
	sorted.sort_custom(_compare_teams)

	# Строки таблицы
	for i in range(sorted.size()):
		var team : Dictionary = sorted[i]
		var gf : int = int(team["goals_for"])
		var ga : int = int(team["goals_against"])
		var diff : int = gf - ga
		
		# Определяем цвет для топ-3
		var text_color : Color = Color.WHITE
		if i == 0:
			text_color = GOLD_COLOR
		elif i == 1:
			text_color = SILVER_COLOR
		elif i == 2:
			text_color = BRONZE_COLOR
		
		# Создаем ячейки
		var team_name : String = _truncate_team_name(tr(String(team["name"])))
		var cells : Array = [
			team_name,
			str(team["points"]),
			str(gf),
			str(ga),
			str(diff)
		]
		
		for cell_text in cells:
			var cell : Label = _create_label(cell_text, false, text_color)
			table_container.add_child(cell)

# ---------- создание Label с настройками ----------
func _create_label(text : String, is_header : bool = false, color : Color = Color.WHITE) -> Label:
	var label : Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Настройка шрифта
	label.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	
	# Размеры ячеек
	if is_header:
		label.custom_minimum_size = Vector2(150, 40)
	else:
		label.custom_minimum_size = Vector2(150, 30)
	
	# Для длинных имен команд
	if not is_header and text.length() > 12:
		label.clip_contents = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	return label

# ---------- обрезка длинных имен команд ----------
func _truncate_team_name(team_name : String) -> String:
	if team_name.length() > 12:
		return team_name.substr(0, 10) + "..."
	return team_name

# ---------- вывод места игрока ----------
func _show_player_place() -> void:
	var sorted : Array = Score.teams.duplicate(true)
	sorted.sort_custom(_compare_teams)
	var player_place : int = -1
	var player_name : String = Score.player_team_name
	
	# Находим место игрока
	for i in range(sorted.size()):
		if String(sorted[i]["name"]) == player_name:
			player_place = i + 1
			break
	
	if player_place >= 1:
		var message : String = tr("Поздравляем — вы заняли {v}-е место!").format({"v": player_place})
		place_label.text = message
	else:
		place_label.text = tr("Компьютер занял {v}-е место").format({"v": player_place})

# ---------- компаратор команд ----------
func _compare_teams(a : Dictionary, b : Dictionary) -> bool:
	var pa : int = int(a["points"])
	var pb : int = int(b["points"])
	if pa == pb:
		var da : int = int(a["goals_for"]) - int(a["goals_against"])
		var db : int = int(b["goals_for"]) - int(b["goals_against"])
		if da == db:
			return int(a["goals_for"]) > int(b["goals_for"])
		return da > db
	return pa > pb

# ---------- кнопка «В меню» ----------
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# ---------- кнопка «Replay» ----------
func _on_replay_pressed() -> void:
	if Score.has_method("reset"):
		Score.reset()
	get_tree().change_scene_to_file("res://scenes/tournament_menu.tscn")
