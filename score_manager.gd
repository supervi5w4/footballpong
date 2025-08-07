# ------------------------------------------------------------
#  score_manager.gd – Менеджер турнира и счёта
#  (Autoload Singleton) • Godot 4.4.1 | GDScript 2.0
# ------------------------------------------------------------
extends Node

"""
Менеджер турнира Football Pong:
• хранит команды, матчи и туры
• генерирует расписание (двойной круг «каждый-с-каждым»)
• симулирует матчи ботов с учётом силы
• ведёт счёт текущего матча (left/right)
"""

# ---------- 1. Счёт текущего матча ----------
var left:  int = 0
var right: int = 0
var ad_shown: bool = false

# ---------- 2. Данные турнира ----------
var player_team_name: String = ""
var teams:   Array = []       # Array<Dictionary>
var matches: Array = []       # Array<Dictionary>
var rounds:  Array = []       # Array<Array>
var current_round:  int = 0
var current_match:  int = -1

# ---------- 3. Генерация календаря ----------
func generate_matches() -> void:
	matches.clear()
	rounds.clear()

	# список имён команд
	var names: Array[String] = []
	for t in teams:
		names.append(String(t["name"]))

	# нечётное количество → BYE-команда
	if names.size() % 2 != 0:
		names.append("__BYE__")

	var n: int = names.size()
	var half: int = n >> 1     # безопасное целочисленное деление

	# ---- первый круг ----
	for _r in range(n - 1):
		var round_idxs: Array[int] = []
		for i in range(half):
			var home_name := names[i]
			var away_name := names[n - 1 - i]
			if home_name != "__BYE__" and away_name != "__BYE__":
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

	current_round  = 0
	current_match  = -1

# ---------- 4. Вспомогательные ----------
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

# ---------- 5. Симуляция матчей ботов тура ----------
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

# ---------- 6. Симуляция одного матча ----------
func _simulate_single_match(index: int) -> void:
	var m: Dictionary = matches[index]
	var home: String = String(m["home"])
	var away: String = String(m["away"])

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var gh: int = _random_goals(rng)
	var ga: int = _random_goals(rng)

	# корректировка по силе
	var sh: float = float(get_team_dict(home).get("strength", 1.0))
	var sa: float = float(get_team_dict(away).get("strength", 1.0))
	if abs(sh - sa) >= 0.05 and rng.randf() < 0.5:
		if sh > sa:
			gh += 1
		else:
			ga += 1

	# 25 % — ничья
	if rng.randf() < 0.25:
		ga = gh
	# 10 % — бонус хозяевам
	elif rng.randf() < 0.10:
		gh += 1

	m["score"]  = "%d:%d" % [gh, ga]
	m["played"] = true

	var ht: Dictionary = get_team_dict(home)
	var at: Dictionary = get_team_dict(away)

	ht["goals_for"]      = int(ht.get("goals_for", 0))      + gh
	ht["goals_against"]  = int(ht.get("goals_against", 0))  + ga
	at["goals_for"]      = int(at.get("goals_for", 0))      + ga
	at["goals_against"]  = int(at.get("goals_against", 0))  + gh

	if gh > ga:
		ht["points"] = int(ht.get("points", 0)) + 3
	elif gh < ga:
		at["points"] = int(at.get("points", 0)) + 3
	else:
		ht["points"] = int(ht.get("points", 0)) + 1
		at["points"] = int(at.get("points", 0)) + 1

# ---------- 7. Генерация правдоподобного счёта ----------
func _random_goals(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
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
