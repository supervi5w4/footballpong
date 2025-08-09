# ------------------------------------------------------------
# score_manager.gd — Менеджер турнира и счёта
# (Autoload Singleton) • Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Node

"""
Менеджер турнира Football Pong:
• хранит команды, матчи и туры
• генерирует расписание (двойной круг «каждый-с-каждым»)
• симулирует матчи ботов с учётом силы
• ведёт счёт текущего матча (left/right)
"""

# ---------- 1) Сигналы и счёт текущего матча ----------
signal score_changed(left: int, right: int)

var _left: int = 0
var _right: int = 0

var left: int:
	get: return _left
	set(value):
		_left = value
		score_changed.emit(_left, _right)

var right: int:
	get: return _right
	set(value):
		_right = value
		score_changed.emit(_left, _right)

func reset_score() -> void:
	_left = 0
	_right = 0
	score_changed.emit(_left, _right)

func set_score(l: int, r: int) -> void:
	_left = l
	_right = r
	score_changed.emit(_left, _right)

# ---------- 2) Турнирные данные ----------
var ad_shown: bool = false
var player_team_name: String = ""
var teams: Array[Dictionary] = []      # [{name, strength, points, goals_for, goals_against}]
var matches: Array[Dictionary] = []    # [{home, away, played, score}]
var rounds: Array[Array] = []          # [[match_idx...], ...]
var current_round: int = 0
var current_match: int = -1
var player_is_home: bool = true        # true → игрок хозяин, влияет на отображение счёта

const BYE := "__BYE__"
const STRENGTH_MIN := 0.10
const STRENGTH_MAX := 1.00

# ---------- 3) Генерация календаря ----------
func generate_matches() -> void:
	matches.clear()
	rounds.clear()

	# список имён команд
	var names: Array[String] = []
	for t in teams:
		names.append(String(t["name"]))

	# нечётное количество → BYE-команда
	if names.size() % 2 != 0:
		names.append(BYE)

	var n: int = names.size()
	var half: int = n >> 1  # целочисленное деление на 2

	# ---- первый круг ----
	for _r in range(n - 1):
		var round_idxs: Array[int] = []
		for i in range(half):
			var home_name := names[i]
			var away_name := names[n - 1 - i]
			if home_name != BYE and away_name != BYE:
				matches.append({
					"home": home_name,
					"away": away_name,
					"played": false,
					"score": "—"
				})
				round_idxs.append(matches.size() - 1)
		rounds.append(round_idxs)

		# ротация (фиксирован элемент 0)
		names.insert(1, names.pop_back())

	# ---- зеркальный второй круг ----
	var first_rounds := rounds.duplicate()
	for old_round in first_rounds:
		var mirror: Array[int] = []
		for idx in old_round:
			var m: Dictionary = matches[idx]
			matches.append({
				"home": String(m["away"]),
				"away": String(m["home"]),
				"played": false,
				"score": "—"
			})
			mirror.append(matches.size() - 1)
		rounds.append(mirror)

	current_round = 0
	current_match = -1

# Удобно: перейти к следующему туру (если нужно снаружи)
func advance_round() -> void:
	if current_round < rounds.size() - 1:
		current_round += 1
		current_match = -1

# ---------- 4) Вспомогательные ----------
func get_team_dict(t_name: String) -> Dictionary:
	for t in teams:
		if String(t["name"]) == t_name:
			return t
	return {}

func is_tournament_over() -> bool:
	for m in matches:
		if not m["played"]:
			return false
	return true

# ---------- 5) Симуляция матчей ботов тура ----------
func simulate_bot_matches() -> void:
	if current_round >= rounds.size():
		return
	for idx in rounds[current_round]:
		var m: Dictionary = matches[idx]
		if m["played"]:
			continue
		if m["home"] == player_team_name or m["away"] == player_team_name:
			continue
		_simulate_single_match(idx)

# ---------- 6) Симуляция одного матча ----------
func _simulate_single_match(index: int) -> void:
	var m: Dictionary = matches[index]
	var home: String = String(m["home"])
	var away: String = String(m["away"])

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var gh: int = _random_goals(rng)
	var ga: int = _random_goals(rng)

	# корректировка по силе
	var sh: float = clamp(float(get_team_dict(home).get("strength", 1.0)), STRENGTH_MIN, STRENGTH_MAX)
	var sa: float = clamp(float(get_team_dict(away).get("strength", 1.0)), STRENGTH_MIN, STRENGTH_MAX)

	# относительная сила может добавить гол(ы)
	var diff: float = sh - sa
	var abs_diff: float = abs(diff)
	if abs_diff > 0.0 and rng.randf() < abs_diff:
		var extra: int = rng.randi_range(1, int(abs_diff * 3.0) + 1)
		if diff > 0.0:
			gh += extra
		else:
			ga += extra

	# шанс ничьей уменьшается при большей разнице силы
	var draw_chance: float = clamp(0.25 - abs_diff * 0.15, 0.05, 0.25)
	if rng.randf() < draw_chance:
		ga = gh
	else:
		# бонус хозяев зависит от относительной силы
		var home_bonus_chance: float = clamp(0.10 + diff * 0.10, 0.0, 0.5)
		if rng.randf() < home_bonus_chance:
			gh += 1

	m["score"] = "%d:%d" % [gh, ga]
	m["played"] = true

	var ht: Dictionary = get_team_dict(home)
	var at: Dictionary = get_team_dict(away)

	ht["goals_for"]     = int(ht.get("goals_for", 0)) + gh
	ht["goals_against"] = int(ht.get("goals_against", 0)) + ga
	at["goals_for"]     = int(at.get("goals_for", 0)) + ga
	at["goals_against"] = int(at.get("goals_against", 0)) + gh

	if gh > ga:
		ht["points"] = int(ht.get("points", 0)) + 3
	elif gh < ga:
		at["points"] = int(at.get("points", 0)) + 3
	else:
		ht["points"] = int(ht.get("points", 0)) + 1
		at["points"] = int(at.get("points", 0)) + 1

# ---------- 7) Генерация правдоподобного счёта ----------
func _random_goals(rng: RandomNumberGenerator) -> int:
	var r: float = rng.randf()
	if r < 0.30:
		return rng.randi_range(0, 1)     # 0–1
	elif r < 0.60:
		return 2
	elif r < 0.90:
		return 3
	elif r < 0.98:
		return 4
	else:
		return 5 + rng.randi_range(0, 2) # 5–7 (редко)

# ---------- 8) (Опционально) таблица для календаря/итогов ----------
func get_table() -> Array[Dictionary]:
	# возвращает новый массив, отсортированный по очкам, разнице мячей, забитым
	var table := teams.duplicate(true)
	table.sort_custom(func(a, b):
		var pa := int(a.get("points", 0))
		var pb := int(b.get("points", 0))
		if pa != pb: return pa > pb
		var gda := int(a.get("goals_for", 0)) - int(a.get("goals_against", 0))
		var gdb := int(b.get("goals_for", 0)) - int(b.get("goals_against", 0))
		if gda != gdb: return gda > gdb
		return int(a.get("goals_for", 0)) > int(b.get("goals_for", 0))
	)
	return table
