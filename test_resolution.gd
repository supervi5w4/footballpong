extends Node2D

# Тестовый скрипт для проверки системы адаптивного разрешения
# Запустите эту сцену и измените размер окна для проверки

@onready var game_scene: Game = $Game

func _ready() -> void:
	print("=== Тест системы адаптивного разрешения ===")
	print("Текущий размер viewport: ", get_viewport_rect().size)
	
	if game_scene:
		print("Game scene loaded successfully")
		print("Field bounds: ", game_scene.get_field_bounds())
		print("Goal positions: ", game_scene.get_goal_positions())
		print("Spawn position: ", game_scene.get_spawn_position())
	else:
		print("ERROR: Game scene not found!")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("=== Перезагрузка позиций ===")
			if game_scene:
				game_scene._calculate_viewport_scale()
				game_scene._position_field_elements()
				print("Позиции пересчитаны")
		
		elif event.keycode == KEY_I:
			print("=== Информация о поле ===")
			if game_scene:
				print("Viewport size: ", get_viewport_rect().size)
				print("Field bounds: ", game_scene.get_field_bounds())
				print("Goal positions: ", game_scene.get_goal_positions())
				print("Spawn position: ", game_scene.get_spawn_position())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		print("=== Размер окна изменился ===")
		print("Новый размер: ", get_viewport_rect().size)
