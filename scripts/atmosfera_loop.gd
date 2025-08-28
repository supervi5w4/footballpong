extends AudioStreamPlayer

func _ready() -> void:
	print("Atmosfera: _ready() вызван")
	print("Atmosfera: stream = ", stream)
	print("Atmosfera: volume_db = ", volume_db)
	print("Atmosfera: bus = ", bus)
	print("Atmosfera: autoplay = ", autoplay)
	finished.connect(_on_finished)
	if autoplay:
		print("Atmosfera: автозапуск включен")

func _on_finished() -> void:
	print("Atmosfera: трек закончился, перезапускаю")
	play()
