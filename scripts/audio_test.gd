extends Node

func _ready() -> void:
	print("=== АУДИО ТЕСТ ===")
	print("AudioServer.get_bus_count(): ", AudioServer.get_bus_count())
	
	for i in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(i)
		var bus_volume = AudioServer.get_bus_volume_db(i)
		var bus_muted = AudioServer.is_bus_mute(i)
		print("Шина ", i, ": ", bus_name, " (громкость: ", bus_volume, " дБ, выключена: ", bus_muted, ")")
	
	# Проверяем, есть ли AudioStreamPlayer в сцене
	var atmosfera = get_node_or_null("../Atmosfera")
	if atmosfera:
		print("Atmosfera найден!")
		print("  - stream: ", atmosfera.stream)
		print("  - volume_db: ", atmosfera.volume_db)
		print("  - bus: ", atmosfera.bus)
		print("  - autoplay: ", atmosfera.autoplay)
		print("  - playing: ", atmosfera.playing)
	else:
		print("Atmosfera НЕ найден!")
		# Попробуем найти по-другому
		var game = get_parent()
		if game:
			atmosfera = game.get_node_or_null("Atmosfera")
			if atmosfera:
				print("Atmosfera найден через get_parent()!")
				print("  - stream: ", atmosfera.stream)
				print("  - volume_db: ", atmosfera.volume_db)
				print("  - bus: ", atmosfera.bus)
				print("  - autoplay: ", atmosfera.autoplay)
				print("  - playing: ", atmosfera.playing)
			else:
				print("Atmosfera НЕ найден даже через get_parent()!")
				# Выведем всех детей Game
				print("Дети Game:")
				for child in game.get_children():
					print("  - ", child.name, " (", child.get_class(), ")")
	
	print("==================")
