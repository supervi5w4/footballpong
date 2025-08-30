extends Node

func _ready():
	print("=== ТЕСТ ГРАНИЦ ПОЛЯ ===")
	
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
	
	print("✅ Тест завершен")
	get_tree().quit()
