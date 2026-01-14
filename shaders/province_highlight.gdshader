shader_type canvas_item;

uniform sampler2D mask_tex : filter_nearest, repeat_disable;

// 0 = owner view, 1 = province view
uniform int view_mode = 0;

uniform vec4 prov_colors[8];
uniform vec4 owner_colors[8];
uniform vec4 terrain_colors[8];

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float enabled_outline = 1.0;
uniform float tolerance = 0.002;   // ~0.5 / 255
uniform float thickness_px = 1.0;

// Selected province (mask RGB normalized 0..1)
uniform vec4 selected_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float enabled_selection = 0.0;

float matches(vec3 a, vec3 b) {
	return 1.0 - step(tolerance, distance(a, b));
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 m0 = texture(mask_tex, UV).rgb;

	// Water/empty = black -> show base map
	float is_land = step(0.0001, m0.r + m0.g + m0.b);

	// ----- Recolor pass -----
	vec3 recolor = base.rgb;

	if (is_land > 0.5) {
		// Find which province this pixel belongs to (0..7)
		float best = 0.0;
		int idx = 0;

		for (int i = 0; i < 8; i++) {
			float s = matches(m0, prov_colors[i].rgb);
			// Keep the first match; mask should be exact so this is fine
			if (s > best) {
				best = s;
				idx = i;
			}
		}

		// If match, color according to view mode, else fall back to base color
		if (best > 0.5) {
			if (view_mode == 0) { // Owner view
				recolor = owner_colors[idx].rgb;
			} else if (view_mode == 1){ // Province view
				recolor = prov_colors[idx].rgb;
			}else { // Terrain view
				recolor = terrain_colors[idx].rgb;
			}
		}
	}

	// ----- Outline pass (selected province edges only) -----
	float do_outline = enabled_selection * enabled_outline;
	float sel0 = matches(m0, selected_color.rgb) * is_land;

	vec2 mask_px = vec2(1.0) / vec2(textureSize(mask_tex, 0));
	vec2 px = mask_px * thickness_px;

	vec3 ml = texture(mask_tex, UV + vec2(-px.x, 0.0)).rgb;
	vec3 mr = texture(mask_tex, UV + vec2( px.x, 0.0)).rgb;
	vec3 mu = texture(mask_tex, UV + vec2(0.0, -px.y)).rgb;
	vec3 md = texture(mask_tex, UV + vec2(0.0,  px.y)).rgb;

	float edge = 0.0;
	edge = max(edge, 1.0 - matches(ml, selected_color.rgb));
	edge = max(edge, 1.0 - matches(mr, selected_color.rgb));
	edge = max(edge, 1.0 - matches(mu, selected_color.rgb));
	edge = max(edge, 1.0 - matches(md, selected_color.rgb));

	edge *= sel0 * do_outline;

	// Compose
	vec3 out_rgb = mix(recolor, outline_color.rgb, step(0.5, edge));
	COLOR = vec4(out_rgb, base.a);
}
