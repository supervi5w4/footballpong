shader_type canvas_item;

// ---- параметры настраиваются в Inspector ----
uniform float amplitude   : hint_range(0.0, 20.0) = 10.0;   // высота волн (px)
uniform float wavelength1 : hint_range(5.0, 100.0) = 50.0; // первая волна
uniform float wavelength2 : hint_range(5.0, 100.0) = 50.0; // вторая (мелкая)
uniform float speed       : hint_range(0.1, 5.0) = 3.0;    // скорость ветра

void fragment() {
    // размер текстуры
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    // координаты текущего пикселя
    vec2 uv_px    = UV * tex_size;

    // две синус-волны разного масштаба
    float wave_big  = sin((uv_px.x / wavelength1) + TIME * speed);
    float wave_small= sin((uv_px.x / wavelength2) + TIME * speed * 1.6);

    float offset = (wave_big * 0.6 + wave_small * 0.4) * amplitude;

    // вертикальный сдвиг (делим на высоту, чтобы получить UV)
    vec2 shifted_uv = UV + vec2(0.0, offset / tex_size.y);

    COLOR = texture(TEXTURE, shifted_uv);
    // сохраняем альфу (можно удалить строку — тот же результат)
    COLOR.a *= texture(TEXTURE, shifted_uv).a;
}
