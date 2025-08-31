# РЕАЛИЗАЦИЯ ПРЯМОГО ПЕРЕХОДА В МЕНЮ

## Цель
После завершения турнира нажатие кнопки "Меню" на финальной таблице должно сразу загружать `scenes/menu.tscn` без диалога подтверждения.

## Выполненные изменения

### 1. Изменение функции `_on_menu_pressed` в `scenes/final_table.gd`

**Было:**
```gdscript
func _on_menu_pressed() -> void:
	# Подтверждение перед выходом
	var dialog = AcceptDialog.new()
	dialog.title = tr("Подтверждение")
	dialog.dialog_text = tr("Вы уверены, что хотите вернуться в меню?")
	dialog.add_theme_font_override("font", load("res://fonts/PressStart2P-Regular.ttf"))
	dialog.add_theme_font_size_override("font_size", FONT_SIZE)
	
	dialog.confirmed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	
	add_child(dialog)
	dialog.popup_centered()
```

**Стало:**
```gdscript
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
```

### 2. Удаление строк переводов

Удалены следующие строки из всех файлов переводов:

#### Из `i18n/locale.csv`:
- `Подтверждение,Confirmation,Подтверждение`
- `Вы уверены, что хотите вернуться в меню?,Are you sure you want to return to the menu?,Вы уверены, что хотите вернуться в меню?`

#### Из `i18n/locale.en.translation.txt`:
- `"Подтверждение": "Confirmation"`
- `"Вы уверены, что хотите вернуться в меню?": "Are you sure you want to return to the menu?"`

#### Из `i18n/locale.ru.translation.txt`:
- `"Подтверждение": "Подтверждение"`
- `"Вы уверены, что хотите вернуться в меню?": "Вы уверены, что хотите вернуться в меню?"`

### 3. Пересборка скомпилированных файлов переводов

Удалены скомпилированные файлы переводов:
- `i18n/locale.en.translation`
- `i18n/locale.ru.translation`

Godot автоматически пересоберет эти файлы при следующем запуске проекта.

## Результат

✅ **Кнопка "В меню" теперь работает мгновенно** - без диалогов подтверждения
✅ **Удален весь код AcceptDialog** - больше нет создания диалогов
✅ **Очищены файлы переводов** - удалены неиспользуемые строки
✅ **Переход происходит напрямую** - `get_tree().change_scene_to_file("res://scenes/menu.tscn")`

## Проверка

- [x] Функция `_on_menu_pressed` упрощена до одной строки
- [x] Удален весь код AcceptDialog
- [x] Удалены строки переводов из всех файлов
- [x] Удалены скомпилированные файлы переводов
- [x] Нет оставшихся ссылок на удаленные строки в коде

Теперь после завершения турнира нажатие кнопки "В меню" сразу переводит игрока в главное меню без дополнительных подтверждений.
