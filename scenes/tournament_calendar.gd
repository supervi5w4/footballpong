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

func _update_round_info() -> void:
	var total_rounds : int = Score.rounds.size()
	round_label.text = "Тур %d из %d" % [Score.current_round + 1, total_rounds]
	_render_calendar()
	_render_table()

func _render_calendar() -> void:
	for child in matches_list.get_children():
		child.queue_free()
	var round_idxs : Array = Score.rounds[Score.current_round]
	for idx in round_idxs:
		var m : Dictionary = Score.matches[idx] as Dictionary
		var home : String = String(m["home"])
		var away : String = String(m["away"])
		var score_text : String = String(m["score"])
		var lbl : Label = Label.new()
		lbl.text = "%s — %s    %s" % [home, away, score_text]
		matches_list.add_child(lbl)

func _render_table() -> void:
	for child in rows_container.get_children():
		child.queue_free()
	var headers : Array = ["Команда", "Очки", "Забито", "Пропущено", "Разница"]
	for h in headers:
		var hl : Label = Label.new()
		hl.text = String(h)
		rows_container.add_child(hl)
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
