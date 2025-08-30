extends Node

func _ready():
	print("=== ПРОСТОЙ ТЕСТ AI РАКЕТКИ ===")
	
	# Ждем инициализацию
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("Game/AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена")
	
	# Проверяем настройки
	print("📋 Настройки:")
	print("   ball_path: ", ai_paddle.ball_path)
	print("   player_path: ", ai_paddle.player_path)
	print("   defends_right_side: ", ai_paddle.defends_right_side)
	print("   skill: ", ai_paddle.skill)
	
	# Проверяем physics_process
	print("📋 Physics Process:")
	print("   is_physics_processing(): ", ai_paddle.is_physics_processing())
	
	# Проверяем позиции
	print("📋 Позиции:")
	print("   AI позиция: ", ai_paddle.global_position)
	
	# Находим мяч и игрока напрямую
	var ball = get_node_or_null("Game/Ball")
	var player = get_node_or_null("Game/PlayerPaddle")
	
	if ball:
		print("   Мяч позиция: ", ball.global_position)
	else:
		print("   ❌ Мяч не найден!")
	
	if player:
		print("   Игрок позиция: ", player.global_position)
	else:
		print("   ❌ Игрок не найден!")
	
	# Проверяем внутренние переменные AI
	print("📋 Внутренние переменные AI:")
	print("   _ball: ", ai_paddle._ball)
	print("   _player: ", ai_paddle._player)
	print("   _target_pos: ", ai_paddle._target_pos)
	print("   _smooth_target_pos: ", ai_paddle._smooth_target_pos)
	print("   _state: ", ai_paddle._state)
	print("   velocity: ", ai_paddle.velocity)
	
	# Запускаем мониторинг
	start_monitoring(ai_paddle)

var monitoring = false

func start_monitoring(ai_paddle):
	monitoring = true
	print("\n🔄 Запуск мониторинга...")
	
	var frame_count = 0
	while monitoring and frame_count < 600:  # 10 секунд при 60 FPS
		await get_tree().process_frame
		frame_count += 1
		
		# Проверяем каждую секунду
		if frame_count % 60 == 0:
			var old_pos = ai_paddle.global_position
			await get_tree().process_frame
			var new_pos = ai_paddle.global_position
			var movement = new_pos - old_pos
			
			print("Кадр ", frame_count, ":")
			print("   Движение: ", movement, " (длина: ", movement.length(), ")")
			print("   Скорость: ", ai_paddle.velocity)
			print("   Цель: ", ai_paddle._target_pos)
			print("   Состояние: ", ai_paddle._state)
			print("   Physics process: ", ai_paddle.is_physics_processing())
			
			if movement.length() > 1.0:
				print("   ✅ AI движется!")
			else:
				print("   ⚠️ AI не движется")
	
	print("🛑 Мониторинг завершен")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		monitoring = false
		get_tree().quit()
