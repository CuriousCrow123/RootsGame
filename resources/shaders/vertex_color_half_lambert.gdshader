shader_type spatial;
render_mode ambient_light_disabled;

uniform float wrap : hint_range(0.0, 1.0) = 0.5;
uniform vec4 albedo_tint : source_color = vec4(0.39, 0.40, 0.35, 1.0);

void fragment() {
	ALBEDO = COLOR.rgb * albedo_tint.rgb;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float wrapped = (NdotL + wrap) / (1.0 + wrap);
	float diffuse = max(0.0, wrapped);
	DIFFUSE_LIGHT += diffuse * ATTENUATION * LIGHT_COLOR / PI;
}
