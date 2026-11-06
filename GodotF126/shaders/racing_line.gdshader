shader_type spatial;
// Línea de trazada (Paso 38). Por vértice: UV.x = velocidad objetivo (m/s; 999 = sin
// límite) y UV.y = metros desde el comienzo del trazado; UV2.x = 0 / 1 de un borde al otro.
// Sólo se dibuja de view_behind m detrás del auto a view_ahead m adelante. El color sale de
// la velocidad del auto contra la objetivo: verde (sobra velocidad), amarillo (levantar)
// y rojo (frenar: el auto va más rápido de lo que puede ir en ese punto).
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform float car_speed = 0.0;
uniform float car_distance = 0.0;
uniform float track_length = 1000.0;
uniform float view_ahead = 280.0;
uniform float view_behind = 12.0;
uniform float fade = 60.0;
uniform float yellow_span = 4.2;
uniform float red_margin = 1.4;
uniform float braking_only = 0.0;
uniform float opacity = 0.8;
uniform vec3 color_go : source_color = vec3(0.15, 0.85, 0.3);
uniform vec3 color_lift : source_color = vec3(1.0, 0.8, 0.1);
uniform vec3 color_brake : source_color = vec3(0.95, 0.12, 0.1);

varying vec2 line_data;
varying float across;

void vertex() {
	line_data = UV;
	across = UV2.x;
}

void fragment() {
	float d = mod(line_data.y - car_distance + track_length * 0.5, track_length) - track_length * 0.5;
	if (d < -view_behind || d > view_ahead) {
		discard;
	}
	float alpha = opacity * (1.0 - smoothstep(view_ahead - fade, view_ahead, d))
		* smoothstep(-view_behind, -view_behind + 4.0, d);
	float u = clamp((car_speed - line_data.x + yellow_span) / (yellow_span + red_margin), 0.0, 1.0);
	vec3 color = u < 0.5 ? mix(color_go, color_lift, u * 2.0) : mix(color_lift, color_brake, (u - 0.5) * 2.0);
	alpha *= mix(1.0, smoothstep(0.3, 0.55, u), braking_only);
	alpha *= smoothstep(0.0, 0.2, across) * smoothstep(1.0, 0.8, across);
	ALBEDO = color;
	ALPHA = alpha;
}
