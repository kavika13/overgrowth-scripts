uniform sampler2D tex0;
uniform sampler2D tex1;
uniform float radius;

const float rotation_inc = 360.0/8.0;

float GetDepthOffset(sampler2D dep, float bias) {
	vec4 depth_tex = texture2D(dep,gl_TexCoord[0].xy);

	float rotation_deg = bias;
	float rotation_rad = rotation_deg * 0.0174532925;

	float depth = depth_tex.r;
	float near = 0.1;
	float far = 1000.0;
	float distance = depth * (far-near) + near;
	float dist_from_center = radius - distance;
	if(dist_from_center < -radius){
		return 0.0;
	}

	vec2 point = vec2(gl_TexCoord[0].x*2.0-1.0, dist_from_center/radius);
	float rotated_point_x = point.y*sin(rotation_rad) + 
							point.x*cos(rotation_rad); 

	return (rotated_point_x - point.x)*0.5;
}

void main()
{	
	if(gl_TexCoord[0].x < 0.02 || gl_TexCoord[0].x > 0.98 ||
	   gl_TexCoord[0].y < 0.02 || gl_TexCoord[0].y > 0.98)
	{
		discard;
	}

	float offset1 = GetDepthOffset(tex0, -rotation_inc);
	float offset2 = GetDepthOffset(tex1, rotation_inc);

	gl_FragColor = vec4(offset1*0.5+0.5,offset2*0.5+0.5,0.0,1.0);
}