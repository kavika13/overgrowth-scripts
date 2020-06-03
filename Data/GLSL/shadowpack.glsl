vec2 GetShadowCoords() {
	vec2 shadow_coords = gl_MultiTexCoord3.xy;
	shadow_coords *= gl_MultiTexCoord7.zw;
	shadow_coords += gl_MultiTexCoord7.xy;
	return shadow_coords;
}

