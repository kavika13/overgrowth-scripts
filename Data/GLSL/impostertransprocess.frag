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

	vec3 color;
	
	float offset=1.0/256.0;

	{
		float trans = texture2D(tex0,gl_TexCoord[0].xy).r;
		float sample;
		float total = 0.0;
		if(trans == mid_val){
			float old_trans = trans;
			trans = 0.0;
			sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset,0.0)).r;
			if(sample != mid_val){
				trans += 0.0;
				total += 1.0;
			}
			sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset,0.0)).r;
			if(sample != mid_val){
				trans += 1.0;
				total += 1.0;
			}
			if(total > 0.0){
				trans /= total;
				trans -= 0.5;
				trans *= iter/32.0;
				trans += 0.5;
				trans = max(0.0,min(1.0,trans));
			} else {
				trans = old_trans;
			}
		}
		color.r = trans;
	}

	{
		float trans = texture2D(tex0,gl_TexCoord[0].xy).g;
		float sample;
		float total = 0.0;
		if(trans == mid_val){
			float old_trans = trans;
			trans = 0.0;
			sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset,0.0)).g;
			if(sample != mid_val){
				trans += 0.0;
				total += 1.0;
			}
			sample = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset,0.0)).g;
			if(sample != mid_val){
				trans += 1.0;
				total += 1.0;
			}
			if(total > 0.0){
				trans /= total;
				trans -= 0.5;
				trans *= iter/32.0;
				trans += 0.5;
				trans = max(0.0,min(1.0,trans));
			} else {
				trans = old_trans;
			}
		}
		color.g = trans;
	}

	gl_FragColor = vec4(color.r,color.g,0.0f,1.0f);
}