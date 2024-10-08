shader_type spatial;

uniform vec4 albedo : source_color;
uniform vec4 transmission : source_color;
uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_erode : hint_default_white;
uniform sampler2D texture_erode_timing : hint_default_white;
uniform float proximity_fade_distance;
uniform float erosion_edge : hint_range(0.0, 1.0) = 0.1;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

varying float random_value;

void vertex() {
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0])*length(MODEL_MATRIX[0]),normalize(INV_VIEW_MATRIX[1])*length(MODEL_MATRIX[0]),normalize(INV_VIEW_MATRIX[2])*length(MODEL_MATRIX[2]),MODEL_MATRIX[3]);
	mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	random_value = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	float erode_tex = texture(texture_erode, UV + vec2(random_value, COLOR.a * -0.4)).r;
	float erode_timing = texture(texture_erode_timing, vec2(1.0- COLOR.a)).r;
	
	ALBEDO = albedo.rgb * albedo_tex.rgb * COLOR.rgb;
	BACKLIGHT = transmission.rgb;
	float erosion_alpha = smoothstep(erode_timing - erosion_edge, erode_timing + erosion_edge, erode_tex);
	ALPHA = min(erosion_alpha, albedo_tex.a);
	
	// Proximity Fade
	float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex*2.0-1.0,1.0);
	world_pos.xyz/=world_pos.w;
	ALPHA*=clamp(1.0-smoothstep(world_pos.z+proximity_fade_distance,world_pos.z,VERTEX.z),0.0,1.0);
}
