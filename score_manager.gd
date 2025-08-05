# score_manager.gd
extends Node

var left:  int = 0
var right: int = 0
var ad_shown: bool = false
var teams: Array = []
var matches: Array = []

func generate_matches() -> void:
	matches.clear()
	# Собираем названия команд из массива словарей
	var names : Array[String] = []
	for team_dict in teams:
		names.append(team_dict["name"])
	# Генерируем пары команд (i < j) и две игры для каждой пары
	for i in range(names.size()):
		for j in range(i + 1, names.size()):
			var home := names[i]
			var away := names[j]
			# первая игра: home принимает away
			matches.append({
				"home": home,
				"away": away,
				"played": false,
				"score": "—"
			})
			# ответная игра: away принимает home
			matches.append({
				"home": away,
				"away": home,
				"played": false,
				"score": "—"
			})
