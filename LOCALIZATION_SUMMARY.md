# Отчет о локализации проекта

## Выполненные изменения

### 1. Обернуты строки в tr() в следующих файлах:

#### scenes/final_table.gd
```diff
- %ReplayBtn.text = "Начать турнир заново"
+ %ReplayBtn.text = tr("Начать турнир заново")

- var headers : Array = ["Команда", "Очки", "Забито", "Пропущено", "Разница"]
+ var headers : Array = [tr("Команда"), tr("Очки"), tr("Забито"), tr("Пропущено"), tr("Разница")]

- var message : String = "Поздравляем — вы заняли %d-е место!" % player_place
+ var message : String = tr("Поздравляем — вы заняли {v}-е место!").format({"v": player_place})

- place_label.text = "Компьютер занял %d-е место" % player_place
+ place_label.text = tr("Компьютер занял {v}-е место").format({"v": player_place})

- dialog.title = "Подтверждение"
- dialog.dialog_text = "Вы уверены, что хотите вернуться в меню?"
+ dialog.title = tr("Подтверждение")
+ dialog.dialog_text = tr("Вы уверены, что хотите вернуться в меню?")
```

#### scenes/tournament_calendar.gd
```diff
- round_label.text = "Тур %d из %d" % [Score.current_round + 1, total_rounds]
+ round_label.text = tr("Тур {v1} из {v2}").format({"v1": Score.current_round + 1, "v2": total_rounds})

- round_header.text = "ТУР %d" % (round_index + 1)
+ round_header.text = tr("ТУР {v}").format({"v": round_index + 1})
```

#### test_locale_switch.gd
```diff
- ru_btn.text = "Русский"
+ ru_btn.text = tr("Русский")

- test_label.text = "Быстрая игра"
+ test_label.text = tr("Быстрая игра")

- test_button.text = "Турнир"
+ test_button.text = tr("Турнир")

- test_rich.text = "ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ"
+ test_rich.text = tr("ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ")
```

#### test_locale_safe.gd
```diff
- var test_text = ""
- if TranslationServer.get_locale() == "ru":
-     test_text = "Быстрая игра"
- else:
-     test_text = "Quick Game"
+ var test_text = tr("Быстрая игра")
```

### 2. Обновлен CSV файл переводов

Добавлены новые ключи в `i18n/locale.csv`:

| Ключ | EN | RU |
|------|----|----|
| Начать турнир заново | Restart Tournament | Начать турнир заново |
| Команда | Team | Команда |
| Очки | Points | Очки |
| Забито | Goals For | Забито |
| Пропущено | Goals Against | Пропущено |
| Разница | Difference | Разница |
| Поздравляем — вы заняли {v}-е место! | Congratulations — you took {v}th place! | Поздравляем — вы заняли {v}-е место! |
| Компьютер занял {v}-е место | Computer took {v}th place | Компьютер занял {v}-е место |
| Подтверждение | Confirmation | Подтверждение |
| Вы уверены, что хотите вернуться в меню? | Are you sure you want to return to the menu? | Вы уверены, что хотите вернуться в меню? |
| Тур {v1} из {v2} | Round {v1} of {v2} | Тур {v1} из {v2} |
| ТУР {v} | ROUND {v} | ТУР {v} |
| Русский | Russian | Русский |

### 3. Созданы файлы переводов

- `i18n/locale.en.translation.txt` - английские переводы
- `i18n/locale.ru.translation.txt` - русские переводы

## Использованные шаблоны

### Для строк с переменными:
```gdscript
# Было:
"Счёт: " + str(score)
"Тур %d из %d" % [round, total]

# Стало:
tr("Счёт: {v}").format({"v": score})
tr("Тур {v1} из {v2}").format({"v1": round, "v2": total})
```

### Для простых строк:
```gdscript
# Было:
button.text = "Начать игру"

# Стало:
button.text = tr("Начать игру")
```

## Исключенные строки

Не изменялись:
- Комментарии в коде
- Строки в логах (print, push_warning, push_error)
- Строки с путями ("res://...")
- Строки без кириллицы

## Результат

Проект готов к полной локализации через систему переводов Godot. Все пользовательские строки обернуты в `tr()` и добавлены в CSV файл переводов.
