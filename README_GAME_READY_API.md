# 🎮 Game Ready API для Football Pong

## 📋 Описание

Данный документ описывает интеграцию Game Ready API Яндекс.Игр в проект Football Pong для корректной публикации на платформе.

## ✅ Реализованные функции

### 1. Game Ready API
- **Автоматическая инициализация**: SDK инициализируется при запуске игры
- **Вызов `gameReady()`**: Происходит после загрузки главного меню
- **Совместимость**: Поддерживается как Game Ready API, так и Loading API

### 2. Реклама
- **Между матчами**: Показывается при переходе из меню в игру/турнир
- **При забивании гола**: Показывается с вероятностью 30%
- **Полноэкранная реклама**: Используется `ysdk.adv.showFullscreenAdv()`

### 3. Аналитика
- **Gameplay Started**: Запускается при начале игры
- **Gameplay Stopped**: Останавливается при выходе из игры

## 🔧 Техническая реализация

### JavaScript SDK (`yandex_sdk.js`)
```javascript
function GameReady() {
    // Вызываем Game Ready API
    if (ysdk.features.GameReadyAPI) {
        ysdk.features.GameReadyAPI.gameReady();
        console.log("Game Ready API called");
    }
    
    // Также вызываем Loading API для совместимости
    ysdk.features.LoadingAPI?.ready();
    console.log("Game ready");
}
```

### GDScript SDK (`yandex_sdk.gd`)
```gdscript
func game_ready() -> void:
    if not OS.has_feature("yandex"):
        return
    if not is_game_initialized:
        init_game()
        await game_initialized
    if not is_game_ready:
        is_game_ready = true
        window.GameReady()
        game_ready_api_called.emit()
        print("Game Ready API called successfully")
```

## 🎯 Точки интеграции

### 1. Главное меню (`menu.gd`)
```gdscript
func _ready() -> void:
    # Вызываем Game Ready API после загрузки игры
    if YandexSDK.is_working():
        YandexSDK.game_ready()
```

### 2. Игровая сцена (`game.gd`)
```gdscript
func _ready() -> void:
    # Запускаем аналитику игрового процесса
    if YandexSDK.is_working():
        YandexSDK.gameplay_started()
        _game_started = true

func _exit_tree() -> void:
    # Останавливаем аналитику игрового процесса при выходе
    if YandexSDK.is_working() and _game_started:
        YandexSDK.gameplay_stopped()
```

### 3. Сцена гола (`goal.gd`)
```gdscript
func _on_body_entered(body: Node) -> void:
    # Показываем рекламу при забивании
    YandexSDK.show_interstitial_on_goal()
```

## 📊 Логирование

Для отладки добавлены логи:
- `"Yandex SDK: Game initialized successfully"`
- `"Game Ready API called"`
- `"Game Ready API called successfully"`

## 🚀 Развертывание

1. **Экспорт в HTML5**: Убедитесь, что проект экспортируется с поддержкой Яндекс.Игр
2. **Проверка функций**: Убедитесь, что `OS.has_feature("yandex")` возвращает `true`
3. **Тестирование**: Проверьте работу рекламы и Game Ready API в браузере

## 🔍 Проверка работоспособности

### В консоли браузера должны появиться:
```
Yandex SDK start initialization
Yandex SDK initialized
Game initialized
Game Ready API called
Game ready
```

### Сигналы GDScript:
- `game_initialized` - игра инициализирована
- `game_ready_api_called` - Game Ready API вызван
- `interstitial_ad` - реклама показана/закрыта

## 📝 Требования Яндекс.Игр

✅ **Game Ready API**: Реализован вызов `ysdk.features.GameReadyAPI.gameReady()`  
✅ **Реклама**: Используется `ysdk.adv.showFullscreenAdv()`  
✅ **Аналитика**: Реализованы `gameplayStarted()` и `gameplayStopped()`  
✅ **Инициализация**: SDK инициализируется корректно  

## 🎯 Результат

После внедрения этих изменений ваша игра будет соответствовать требованиям Яндекс.Игр для публикации и корректно использовать Game Ready API.
