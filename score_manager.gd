# score_manager.gd
extends Node

var left:  int = 0
var right: int = 0
var ad_shown: bool = false

# Новые переменные для турнира
var teams: Array = []      # массив словарей с данными команд
var matches: Array = []    # расписание матчей (заполним на следующем шаге)
