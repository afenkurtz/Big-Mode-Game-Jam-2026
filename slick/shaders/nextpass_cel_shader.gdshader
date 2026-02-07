shader_type spatial;
render_mode cull_back, diffuse_toon, specular_toon;

//Toon Shading settings
uniform int diffuse_toon_size = 3; // Number of bands creating color (2-6)
uniform int specular_toon_size = 2; // Specular highlight bands

// Rim lighting
uniform bool enable_rim_light = true;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_threshold = 0.6;
uniform float rim_intensity = 0.5;

void fragment() {
	// inheriting albedo from main material
	// nothing changed from blender file
	ROUGHNESS = 0.8; // controls how sharp toon bands are
	SPECULAR = 0.3; // Specular highlight intensity
	
	// Rim lighting for edge definition
	if (enable_rim_light) {
		float rim = 1.0 - dot(VIEW, NORMAL);
		float rim_light = smoothstep(rim_threshold - 0.1, rim_threshold + 0.1, rim);
		EMISSION = rim_color.rgb * rim_light * rim_intensity;
		
	}
	
}