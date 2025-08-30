extends Node

func _ready() -> void:
	print("=== АУДИО ТЕСТ ===")
	print("AudioServer.get_bus_count(): ", AudioServer.get_bus_count())
	
	for i in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(i)
		var bus_volume = AudioServer.get_bus_volume_db(i)
		var bus_muted = AudioServer.is_bus_mute(i)
		print("Шина ", i, ": ", bus_name, " (громкость: ", bus_volume, " дБ, выключена: ", bus_muted, ")")
	
	# Проверяем Music автолоад
	if Music:
		print("Music автолоад найден!")
		if Music.player:
			print("  - player: ", Music.player)
			print("  - stream: ", Music.player.stream)
			print("  - volume_db: ", Music.player.volume_db)
			print("  - bus: ", Music.player.bus)
			print("  - playing: ", Music.player.playing)
		else:
			print("  - player НЕ найден!")
	else:
		print("Music автолоад НЕ найден!")
	
	print("==================")
