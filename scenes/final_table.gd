# scenes/final_table.gd
extends Control
"""
Финальная таблица турнира.
Отображает отсортированные результаты и место игрока.
Скрипт полностью совместим со строгой типизацией Godot 4 (Errors as Warnings ON).
"""

# ---------- ссылки на UI-узлы ----------
@onready var rows_container : GridContainer = %RowsContainer
@onready var place_label    : Label         = %PlaceLabel
@onready var back_btn       : Button        = %BackToMenuBtn

const COLS : int = 5   # Команда | Очки | GF | GA | Δ

# ---------- старт ----------
func _ready() -> void:
	rows_container.columns = COLS
	_render_table()
	_show_player_place()
	back_btn.pressed.connect(_on_back_pressed)

# ---------- отрисовка таблицы ----------
func _render_table() -> void:
	# очистка старого содержимого
	for c in rows_container.get_children():
		c.queue_free()

	# заголовки
	for h in ["Команда", "Очки", "Забито", "Пропущено", "Разница"]:
		var hdr : Label = Label.new()
		hdr.text = h
		rows_container.add_child(hdr)

	# копия и сортировка
	var sorted : Array = Score.teams.duplicate(true)   # глубокая копия
	sorted.sort_custom(_compare_teams)

	# строки
	for t in sorted:
		var gf : int = int(t["goals_for"])
		var ga : int = int(t["goals_against"])
		var diff : int = gf - ga
		var row : Array = [
			String(t["name"]),
			str(t["points"]),
			str(gf),
			str(ga),
			str(diff)
		]
		for val in row:
			var cell : Label = Label.new()
			cell.text = val
			rows_container.add_child(cell)

# ---------- вывод места игрока ----------
func _show_player_place() -> void:
	var sorted : Array = Score.teams.duplicate(true)
	sorted.sort_custom(_compare_teams)
	var idx : int = -1
	var pname : String = Score.player_team_name
	for i in range(sorted.size()):
		if String(sorted[i]["name"]) == pname:
			idx = i
			break
	if idx >= 0:
		place_label.text = "Вы заняли %d-е место" % (idx + 1)
	else:
		place_label.text = ""

# ---------- компаратор ----------
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
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
