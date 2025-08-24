# Исправление ошибки с spawn_point

## Проблема
Ошибка: обращение к `spawn_point.position`, когда `spawn_point` ещё не инициализирован.

Мяч (Ball) вызывал `get_spawn_position()` в своём `_ready()` до того, как у Game успевали проинициализироваться `@onready`-переменные. В результате `spawn_point == null` и возникала ошибка:
```
Invalid access to property or key 'position' on a base object of type 'Nil'
```

## Решение
Добавлен ленивый поиск узла в функции `get_spawn_position()` и `_position_field_elements()` в `scenes/game.gd`:

### В функции `get_spawn_position()`:
```gdscript
func get_spawn_position() -> Vector2:
	"""Возвращает позицию спавна мяча"""
	if not spawn_point:
		spawn_point = get_node_or_null("SpawnPoint")
	return spawn_point.position if spawn_point else Vector2.ZERO
```

### В функции `_position_field_elements()`:
```gdscript
# Позиционируем точку спавна
if not spawn_point:
	spawn_point = get_node_or_null("SpawnPoint")
if spawn_point:
	spawn_point.position = _scale_position(BASE_SPAWN_POS)
```

## Результат
- Устранена ошибка обращения к null-объекту
- Мяч теперь корректно получает позицию спавна даже при раннем вызове
- Добавлена защита от null-значений с fallback на Vector2.ZERO
