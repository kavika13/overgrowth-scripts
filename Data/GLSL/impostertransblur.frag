uniform sampler2D tex0;
uniform float iter;

const float mid_val = 0.498039216;

void main()
{	
	if(gl_TexCoord[0].x < 0.02 || gl_TexCoord[0].x > 0.98 ||
	   gl_TexCoord[0].y < 0.02 || gl_TexCoord[0].y > 0.98)
	{
		discard;
	}
	float offset=1.0/256.0;

	vec4 color = vec4(0.0);
	vec2 total = vec2(0.0);
	vec4 sample;

	sample = texture2D(tex0,gl_TexCoord[0].xy);
	if(sample.x != mid_val){
		total.x += 2.0;
		color.x += sample.x * 2.0;
	}
	if(sample.y != mid_val){
		total.y += 2.0;
		color.y += sample.y * 2.0;
	}
	sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset,0.0));
	if(sample.x != mid_val){
		total.x += 1.0;
		color.x += sample.x * 1.0;
	}
	if(sample.y != mid_val){
		total.y += 1.0;
		color.y += sample.y * 1.0;
	}
	sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset,0.0));
	if(sample.x != mid_val){
		total.x += 1.0;
		color.x += sample.x * 1.0;
	}
	if(sample.y != mid_val){
		total.y += 1.0;
		color.y += sample.y * 1.0;
	}
	sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,offset));
	if(sample.x != mid_val){
		total.x += 1.0;
		color.x += sample.x * 1.0;
	}
	if(sample.y != mid_val){
		total.y += 1.0;
		color.y += sample.y * 1.0;
	}
	sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,-offset));
	if(sample.x != mid_val){
		total.x += 1.0;
		color.x += sample.x * 1.0;
	}
	if(sample.y != mid_val){
		total.y += 1.0;
		color.y += sample.y * 1.0;
	}

	if(total.x != 0.0){
		color.x /= total.x;
		if(color.x < 0.5 && color.x > 0.48){
			color.x = 0.52;
		}
	} else {
		color.x = mid_val;
	}	
	if(total.y != 0.0){
		color.y /= total.y;
		if(color.y < 0.5 && color.y > 0.48){
			color.y = 0.52;
		}
	} else {
		color.y = mid_val;
	}

	gl_FragColor = vec4(color.xyz,1.0);
}