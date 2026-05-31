shader_type canvas_item;

uniform sampler2D cbcr_texture : filter_linear, repeat_disable;

void fragment() {
	float y = texture(TEXTURE, UV).r;
	vec2 cbcr = texture(cbcr_texture, UV).rg - vec2(0.5, 0.5);
	vec3 rgb = vec3(
		y + 1.403 * cbcr.y,
		y - 0.344 * cbcr.x - 0.714 * cbcr.y,
		y + 1.770 * cbcr.x
	);
	COLOR = vec4(rgb, 1.0);
}
