extends Node

# Тестовый скрипт для диагностики проблем с движением AI ракетки
func _ready():
	print("=== ТЕСТ ДВИЖЕНИЯ AI РАКЕТКИ ===")
	
	# Ждем один кадр для полной инициализации
	await get_tree().process_frame
	
	# Находим AI ракетку
	var ai_paddle = get_node_or_null("../AiPaddle")
	if not ai_paddle:
		print("❌ AI ракетка не найдена!")
		return
	
	print("✅ AI ракетка найдена: ", ai_paddle.name)
	
	# Проверяем, что скрипт загружен
	if not ai_paddle.has_method("_physics_process"):
		print("❌ Скрипт AI ракетки не загружен!")
		return
	
	print("✅ Скрипт AI ракетки загружен")
	
	# Проверяем настройки путей
	print("📋 Настройки путей:")
	print("   ball_path: ", ai_paddle.ball_path)
	print("   player_path: ", ai_paddle.player_path)
	
	# Проверяем, что узлы найдены
	var ball = ai_paddle.get_node_or_null(ai_paddle.ball_path)
	var player = ai_paddle.get_node_or_null(ai_paddle.player_path)
	
	if ball:
		print("✅ Мяч найден: ", ball.name)
	else:
		print("❌ Мяч не найден по пути: ", ai_paddle.ball_path)
	
	if player:
		print("✅ Игрок найден: ", player.name)
	else:
		print("❌ Игрок не найден по пути: ", ai_paddle.player_path)
	
	# Проверяем physics_process
	print("📋 Physics Process:")
	print("   physics_process: ", ai_paddle.is_physics_processing())
	print("   physics_process_internal: ", ai_paddle.is_physics_processing_internal())
	
	# Проверяем позицию и скорость
	print("📋 Позиция и движение:")
	print("   global_position: ", ai_paddle.global_position)
	print("   velocity: ", ai_paddle.velocity)
	print("   start_pos: ", ai_paddle.start_pos)
	
	# Проверяем внутренние переменные
	print("📋 Внутренние переменные:")
	print("   _ball: ", ai_paddle._ball)
	print("   _player: ", ai_paddle._player)
	print("   _target_pos: ", ai_paddle._target_pos)
	print("   _smooth_target_pos: ", ai_paddle._smooth_target_pos)
	print("   _state: ", ai_paddle._state)
	
	# Запускаем мониторинг
	start_monitoring(ai_paddle)

var monitoring = false

func start_monitoring(ai_paddle):
	monitoring = true
	print("\n🔄 Запуск мониторинга движения...")
	
	while monitoring:
		await get_tree().process_frame
		
		# Проверяем движение каждые 60 кадров (1 секунда)
		if Engine.get_process_frames() % 60 == 0:
			var old_pos = ai_paddle.global_position
			await get_tree().process_frame
			var new_pos = ai_paddle.global_position
			var movement = new_pos - old_pos
			
			if movement.length() > 1.0:
				print("✅ AI движется: ", movement, " (скорость: ", movement.length(), ")")
			else:
				print("⚠️ AI не движется (скорость: ", movement.length(), ")")
				print("   velocity: ", ai_paddle.velocity)
				print("   _target_pos: ", ai_paddle._target_pos)
				print("   _smooth_target_pos: ", ai_paddle._smooth_target_pos)
				print("   _state: ", ai_paddle._state)
				print("   physics_process: ", ai_paddle.is_physics_processing())

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		monitoring = false
		print("🛑 Мониторинг остановлен")
		get_tree().quit()
