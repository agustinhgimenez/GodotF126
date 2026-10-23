shader_type spatial;
// Mar Caspio (Paso 23): plano liso con olas sólo en la normal (suma de ondas que se
// mueven). El reflejo del cielo y el brillo del sol salen del PBR de Godot: poca rugosidad
// y la normal ondulada. Cada onda se apaga cuando un píxel cubre más que su longitud
// (si no, de lejos o desde arriba aparecen rayas).

uniform vec3 deep_color : source_color = vec3(0.05, 0.14, 0.2);
uniform vec3 shallow_color : source_color = vec3(0.11, 0.25, 0.32);
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float wave_strength = 0.12;
uniform float wave_scale = 0.8;
uniform float wave_speed = 0.7;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// footprint: metros que cubre un píxel en el agua.
vec2 wave_slope(vec2 p, float t, float footprint) {
	vec2 dirs[5] = { vec2(0.7, 1.0), vec2(1.0, 0.3), vec2(-0.6, 1.0), vec2(0.2, -1.0), vec2(0.9, 0.8) };
	float freqs[5] = { 0.2, 1.0, 1.7, 2.9, 4.3 };
	vec2 slope = vec2(0.0);
	for (int k = 0; k < 5; k++) {
		vec2 d = normalize(dirs[k]);
		float f = freqs[k] * wave_scale;
		float keep = smoothstep(0.8, 0.3, footprint * f);
		float phase = dot(d, p) * f + t * wave_speed * sqrt(freqs[k]) * 2.0;
		slope += d * cos(phase) / freqs[k] * keep * (k == 0 ? 0.25 : 1.0);
	}
	return slope;
}

void fragment() {
	vec2 width = fwidth(world_pos.xz);
	float footprint = max(width.x, width.y);
	vec2 slope = wave_slope(world_pos.xz, TIME, footprint) * wave_strength;
	vec3 n = normalize(vec3(-slope.x, 1.0, -slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	// Más claro cerca de la costa (Z chica), más profundo mar adentro.
	float shore = clamp((world_pos.z - 40.0) / 300.0, 0.0, 1.0);
	ALBEDO = mix(shallow_color, deep_color, shore);
	// Las olas que se apagan de lejos se reemplazan por rugosidad: el brillo se ensancha.
	ROUGHNESS = mix(roughness, 0.3, clamp(footprint / 6.0, 0.0, 1.0));
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
