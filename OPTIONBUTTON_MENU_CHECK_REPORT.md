# Отчет о проверке OptionButton/MenuButton и динамических пунктов меню

## Результаты сканирования проекта

### 1. Поиск OptionButton/MenuButton/PopupMenu в сценах
**Результат**: ❌ Не найдено
- В файлах `.tscn` не обнаружено ни одного OptionButton, MenuButton или PopupMenu
- Все UI элементы в проекте используют Label, Button, RichTextLabel

### 2. Поиск динамических пунктов меню в скриптах
**Результат**: ❌ Не найдено
- Не найдено использование `add_item()`, `set_item_text()`, `get_item_text()`
- Единственные упоминания находятся в `LocaleManager`, который уже правильно обрабатывает переводы

### 3. Поиск массивов строк для пунктов меню
**Результат**: ✅ Найдено 1 место

#### `scenes/tournament_menu.gd` - массив названий команд
```gdscript
const BOT_POOL: Array[Dictionary] = [
	{"name":"Спартак", "strength": 1.00, "ai_style": "aggressive"},
	{"name":"ЦСКА", "strength": 0.97, "ai_style": "aggressive"},
	{"name":"Зенит", "strength": 0.94, "ai_style": "balanced"},
	// ... 27 команд
]
```

**Статус**: ⚠️ Требует внимания
- Названия команд содержат кириллицу
- В данный момент не используются в UI меню
- Если в будущем будут отображаться в OptionButton/MenuButton, потребуется локализация

### 4. Проверка LocaleManager
**Результат**: ✅ Уже правильно настроен
```gdscript
# В i18n/locale_manager.gd уже есть обработка OptionButton:
elif node is OptionButton:
	if "text" in node and typeof(node.text) == TYPE_STRING and node.text != "":
		var original_text = node.text
		var translated_text = tr(original_text)
		node.text = translated_text
	for i in node.item_count:
		var original_item_text = node.get_item_text(i)
		var translated_item_text = tr(original_item_text)
		node.set_item_text(i, translated_item_text)
```

## Выводы

### ✅ Что уже работает правильно:
1. **LocaleManager** уже содержит логику для перевода OptionButton
2. **Нет активного использования** OptionButton/MenuButton в проекте
3. **Система переводов** настроена корректно

### ⚠️ Что требует внимания в будущем:
1. **Названия команд** в `BOT_POOL` содержат кириллицу
2. Если в будущем будет добавлен выбор команд через OptionButton, потребуется:
   - Обернуть названия в `tr()`
   - Добавить переводы в `locale.csv`

## Рекомендации

### 1. Для текущего состояния проекта:
- **Никаких изменений не требуется** - OptionButton/MenuButton не используются
- LocaleManager уже готов к обработке таких элементов

### 2. Для будущих изменений:
Если планируется добавить выбор команд через OptionButton:

```gdscript
# Пример правильной реализации:
func _populate_team_selector() -> void:
	var option_button = $TeamSelector
	option_button.clear()
	
	for team in BOT_POOL:
		option_button.add_item(tr(team["name"]))  # ✅ Обернуть в tr()
```

### 3. Добавить в locale.csv (если понадобится):
```csv
key,en,ru
Спартак,Spartak,Спартак
ЦСКА,CSKA,ЦСКА
Зенит,Zenit,Зенит
Динамо Москва,Dynamo Moscow,Динамо Москва
Динамо Киев,Dynamo Kyiv,Динамо Киев
Шахтёр,Shakhtar,Шахтёр
Торпедо,Torpedo,Торпедо
Локомотив,Lokomotiv,Локомотив
Динамо Минск,Dynamo Minsk,Динамо Минск
Днепр,Dnipro,Днепр
Нефтчи,Neftchi,Нефтчи
Кайрат,Kairat,Кайрат
Черноморец,Chernomorets,Черноморец
Арарат,Ararat,Арарат
Пахтакор,Pakhtakor,Пахтакор
Заря,Zorya,Заря
Металлист,Metallist,Металлист
Ростсельмаш,Rostselmash,Ростсельмаш
Кубань,Kuban,Кубань
Уралмаш,Uralmash,Уралмаш
СКА Ростов,SKA Rostov,СКА Ростов
Таврия,Tavriya,Таврия
Жальгирис,Zalgiris,Жальгирис
Крылья Советов,Krylia Sovetov,Крылья Советов
Сокол,Sokol,Сокол
Анжи,Anzhi,Анжи
Судостроитель,Sudostroitel,Судостроитель
Нистру,Nistru,Нистру
Спартак Орёл,Spartak Orel,Спартак Орёл
Металлург Зап.,Metallurg Zaporizhzhia,Металлург Зап.
```

## Заключение

**Текущий проект не требует изменений** для OptionButton/MenuButton локализации, так как эти элементы не используются. LocaleManager уже готов к их обработке, если они будут добавлены в будущем.
