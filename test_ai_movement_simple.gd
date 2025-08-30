extends Node

func _ready():
	print("=== ПРОСТОЙ ТЕСТ ДВИЖЕНИЯ AI ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Проверяем основные параметры
	print("📋 Основные параметры:")
	print("   Позиция: ", ai_paddle.global_position)
	print("   Скорость: ", ai_paddle.velocity)
	print("   Цель: ", ai_paddle._target_pos)
	print("   Состояние: ", ai_paddle._state)
	print("   Physics process: ", ai_paddle.is_physics_processing())
	
	# Проверяем ссылки на объекты
	print("📋 Ссылки на объекты:")
	print("   _ball: ", ai_paddle._ball)
	print("   _player: ", ai_paddle._player)
	
	# Запускаем мониторинг движения
	start_movement_monitor(ai_paddle)

func start_movement_monitor(ai_paddle):
	print("\n🔄 Мониторинг движения...")
	
	var frame_count = 0
	var last_position = ai_paddle.global_position
	
	while frame_count < 600:  # 10 секунд при 60 FPS
		await get_tree().process_frame
		frame_count += 1
		
		# Проверяем каждую секунду
		if frame_count % 60 == 0:
			var current_position = ai_paddle.global_position
			var movement = current_position - last_position
			var movement_length = movement.length()
			
			print("Секунда ", frame_count / 60, ":")
			print("   Позиция: ", current_position)
			print("   Движение: ", movement, " (длина: ", movement_length, ")")
			print("   Скорость: ", ai_paddle.velocity)
			print("   Цель: ", ai_paddle._target_pos)
			print("   Состояние: ", ai_paddle._state)
			
			if movement_length > 1.0:
				print("   ✅ AI движется!")
			else:
				print("   ⚠️ AI не движется")
			
			last_position = current_position
	
	print("🛑 Мониторинг завершен")
	get_tree().quit()
