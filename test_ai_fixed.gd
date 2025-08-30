extends Node

func _ready():
	print("=== ТЕСТ ИСПРАВЛЕНИЙ AI РАКЕТКИ ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Тестируем функцию get_field_rect()
	print("📋 Тест get_field_rect():")
	var field_rect = ai_paddle.get_field_rect()
	print("   field_rect: ", field_rect)
	print("   position: ", field_rect.position)
	print("   size: ", field_rect.size)
	print("   size.x > 0: ", field_rect.size.x > 0)
	print("   size.y > 0: ", field_rect.size.y > 0)
	
	# Тестируем функцию _clamp_y_to_field()
	print("📋 Тест _clamp_y_to_field():")
	var test_y_values = [-200.0, -100.0, 0.0, 500.0, 1000.0, 1200.0]
	for y in test_y_values:
		var clamped_y = ai_paddle._clamp_y_to_field(y)
		print("   ", y, " -> ", clamped_y)
	
	# Тестируем функцию get_goal_right()
	print("📋 Тест get_goal_right():")
	var goal_right = ai_paddle.get_goal_right()
	print("   goal_right: ", goal_right)
	
	# Тестируем функцию _goal_pos()
	print("📋 Тест _goal_pos():")
	var ball_pos = Vector2(958, 663)
	var goal_pos = ai_paddle._goal_pos(ball_pos)
	print("   ball_pos: ", ball_pos)
	print("   goal_pos: ", goal_pos)
	
	# Тестируем движение AI
	print("📋 Тест движения AI:")
	print("   Позиция: ", ai_paddle.global_position)
	print("   Скорость: ", ai_paddle.velocity)
	print("   Цель: ", ai_paddle._target_pos)
	print("   Состояние: ", ai_paddle._state)
	print("   Physics process: ", ai_paddle.is_physics_processing())
	
	# Запускаем мониторинг движения
	start_movement_monitor(ai_paddle)

func start_movement_monitor(ai_paddle):
	print("\n🔄 Мониторинг движения...")
	
	var frame_count = 0
	var last_position = ai_paddle.global_position
	
	while frame_count < 300:  # 5 секунд при 60 FPS
		await get_tree().process_frame
		frame_count += 1
		
		# Проверяем каждую секунду
		if frame_count % 60 == 0:
			var current_position = ai_paddle.global_position
			var movement = current_position - last_position
			var movement_length = movement.length()
			
			print("Секунда ", frame_count / 60, ":")
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
