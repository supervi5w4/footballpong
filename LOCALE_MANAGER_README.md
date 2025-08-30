# LocaleManager - Система автоматической локализации

## Описание

LocaleManager - это синглтон для автоматической локализации в Godot 4.4.1, который обеспечивает:

- ✅ Автоопределение языка браузера (через JavaScriptBridge)
- ✅ Автоматический перевод всех UI-нод (Label, Button, RichTextLabel и др.)
- ✅ Обновление переводов при переключении языка в реальном времени
- ✅ Отслеживание новых нод в дереве сцены

## Установка

1. **Файл менеджера**: `res://i18n/locale_manager.gd` уже создан
2. **Autoload**: Добавлен в `project.godot` в секции `[autoload]`
3. **Переводы**: Файлы переводов созданы в `res://i18n/`

## Использование

### Автоматический перевод

Все UI-ноды автоматически переводятся при загрузке сцены:

```gdscript
# В любой сцене - перевод происходит автоматически
extends Control

func _ready():
    # LocaleManager уже перевел все тексты
    pass
```

### Ручное переключение языка

```gdscript
# Переключение на английский
var locale_manager = get_node("/root/LocaleManager")
if locale_manager:
    locale_manager.set_lang("en")

# Переключение на русский  
var locale_manager = get_node("/root/LocaleManager")
if locale_manager:
    locale_manager.set_lang("ru")
```

### Принудительный перевод сцены

```gdscript
func _ready():
    # Опционально: принудительно перевести всю сцену
    var locale_manager = get_node("/root/LocaleManager")
    if locale_manager:
        locale_manager.translate_tree(get_tree().root)
```

## Поддерживаемые типы нод

Автоматически переводятся следующие типы UI-нод:
- Label
- Button  
- RichTextLabel
- CheckBox
- CheckButton
- LineEdit
- TextEdit
- MenuButton
- OptionButton (включая элементы списка)

## Автоопределение языка

В веб-версии:
- Если браузер `ru-*` → автоматически русский
- Иначе → английский

В десктопной версии:
- По умолчанию английский

## Тестирование

1. **test_translations.gd** - тест базовой функциональности переводов
2. **test_locale_switch.gd** - тест переключения языков с UI

## Структура файлов

```
res://i18n/
├── locale.csv              # CSV с переводами
├── locale.en.translation   # Английские переводы
├── locale.ru.translation   # Русские переводы
└── locale_manager.gd       # Синглтон менеджера
```

## Добавление новых переводов

1. Добавьте строку в `res://i18n/locale.csv`
2. Обновите файлы `.translation` 
3. Используйте `tr("ключ")` в коде

## Примеры

```gdscript
# В коде
var score_text = tr("Счет: %d") % player_score

# В сценах (автоматически)
Label.text = "Быстрая игра"  # Автоматически переведется
```
