uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec4 ProjShadow;
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

void main()
{	
	float NdotL;
	vec3 color;
	
	vec4 normalmap;
	vec3 map_normal;
	vec4 color_tex;
	float spec;
	
	color_tex = texture2D(tex0,gl_TexCoord[0].xy);
	normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	map_normal = normalize(gl_NormalMatrix*(vec3(normalmap.x, normalmap.z, normalmap.y)*2.0-1.0));
	
	vec3 tangent_normal;
	tangent_normal.x = dot(map_normal, tangent);
	tangent_normal.y = dot(map_normal, bitangent);
	tangent_normal.z = dot(map_normal, normal);
	
	tangent_normal=normalize(tangent_normal);
	tangent_normal.x = tangent_normal.x*0.5+0.5;
	tangent_normal.y = tangent_normal.y*0.5+0.5;
	tangent_normal.z = tangent_normal.z*0.5+0.5;

	color = tangent_normal;

	gl_FragColor = vec4(color,1.0);
}