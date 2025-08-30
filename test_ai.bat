@echo off
echo Запуск теста AI ракетки...
echo.

REM Попробуем найти Godot в разных местах
set GODOT_PATH=

REM Проверяем в PATH
where godot >nul 2>&1
if %errorlevel% == 0 (
    set GODOT_PATH=godot
    goto :found_godot
)

REM Проверяем в стандартных местах
if exist "C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe" (
    set GODOT_PATH="C:\Program Files\Godot\Godot_v4.4.1-stable_win64.exe"
    goto :found_godot
)

if exist "%USERPROFILE%\AppData\Local\Programs\Godot\Godot_v4.4.1-stable_win64.exe" (
    set GODOT_PATH="%USERPROFILE%\AppData\Local\Programs\Godot\Godot_v4.4.1-stable_win64.exe"
    goto :found_godot
)

REM Проверяем в Steam
if exist "%PROGRAMFILES(X86)%\Steam\steamapps\common\Godot\Godot_v4.4.1-stable_win64.exe" (
    set GODOT_PATH="%PROGRAMFILES(X86)%\Steam\steamapps\common\Godot\Godot_v4.4.1-stable_win64.exe"
    goto :found_godot
)

echo Ошибка: Godot не найден!
echo Пожалуйста, установите Godot или добавьте его в PATH
pause
exit /b 1

:found_godot
echo Найден Godot: %GODOT_PATH%
echo Запуск теста...
echo.

%GODOT_PATH% --headless --quit-after 10 test_compilation_simple.tscn

echo.
echo Тест завершен.
pause
