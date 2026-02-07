shader_type spatial;
render_mode unshaded, depth_test_default;

uniform vec4 silhouette_color : source_color = vec4(0.3, 0.5, 1.0, 0.5);

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = silhouette_color.rgb;
	ALPHA = silhouette_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
