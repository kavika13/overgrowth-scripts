uniform sampler2D tex0;
uniform float time;

varying vec3 light_vertex;
varying vec3 vertex;

void main()
{	
	vec3 color;
	vec3 dir = normalize(vertex);
	vec3 light_dir = normalize(light_vertex);
	vec3 light_source = normalize(gl_LightSource[0].position.xyz);
	
	float bright = pow((dot(light_dir, light_source)+1.0)*0.5,4.0);
	float horizon = 1.0-abs(dir.y);
	
	vec2 uv = gl_TexCoord[0].xy;
	
	uv.y = dir.y;
	dir.y = 0.0;
	dir = normalize(dir);
	uv.x =acos(dir.x)/3.1416*2.0;
	if(dir.z<0.0)uv.x*=-1.0;
	uv.x += time;
	
	color = (pow(horizon,2.0)*0.5+0.6)*vec3(0.36,0.40,0.35);
	color = mix(color,gl_LightSource[0].diffuse.xyz,bright*horizon-0.2);
	
	vec4 cloud_tex = texture2D(tex0,uv)*texture2D(tex0,uv*1.5+vec2(time*-0.5,time*-1.3))*texture2D(tex0,uv*2.0+vec2(time*-0.4,time*0.5));
	float cloud_density = min((cloud_tex.a)*1.2,1.0)*pow(horizon,2.0);
	cloud_density=pow(cloud_density,0.8);
	vec3 cloud_normal = normalize(vec3(cloud_tex.r*2.0, cloud_tex.g*2.0, cloud_tex.b*-1.0));
	float cloud_illum = pow((1.0-cloud_density)*0.8,(1.0-bright+cloud_density)*10.0)*bright*3.0*horizon;
	
	float cloud_lit = (dot(light_dir*-1.0,light_source)+1.0)*0.3*(cloud_density)*(1.0-cloud_normal.y)*3.0;
	float cloud_color = (2.0-cloud_density)*0.3*horizon*bright*cloud_normal.y;
	color.xyz = mix(color.xyz,vec3(cloud_illum+cloud_color)+cloud_lit*gl_LightSource[0].diffuse.xyz,min(cloud_density*3.0,1.0));
	
	//color = vec3(1);
	
	gl_FragColor = vec4(color,1.0);
}