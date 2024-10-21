shader_type spatial;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;


uniform float windPower : hint_range(0.0, 1.0);


void vertex() {
	UV=UV* uv1_scale.xy + uv1_offset.xy;
	
	float heightWeight = VERTEX.y;
	float swayValue = sin(TIME) * windPower;
	float z = VERTEX.z + heightWeight * swayValue;
	VERTEX = vec3(VERTEX.x, VERTEX.Y, z)
	
}

void fragment() {
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
