uniform sampler2D tex;
uniform sampler2D tex2;
uniform sampler2DShadow tex3;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;
varying vec4 ProjShadow;
varying vec4 ProjShadow2;
varying vec4 ProjShadow3;
varying vec4 ProjShadow4;
varying vec4 ProjShadow5;
varying vec4 ProjShadow6;

void main()
{	
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	vec3 temp_tangent = normalize(gl_NormalMatrix *gl_MultiTexCoord1.xyz);
	vec3 bitangent = normalize(cross(normal,temp_tangent));
	
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vertex_pos = vec3 (
        dot (temp_tangent, eyeSpaceVert),
        dot (bitangent, eyeSpaceVert),
        dot (normal, eyeSpaceVert));
        
	light_pos.x = dot(gl_LightSource[0].position.xyz, temp_tangent);
	light_pos.y = dot(gl_LightSource[0].position.xyz, bitangent);
	light_pos.z = dot(gl_LightSource[0].position.xyz, normal);
  
	vec3 light_dir = normalize(gl_LightSource[0].position.xyz);
  
    light2_pos.x = dot(gl_LightSource[1].position.xyz, temp_tangent);
	light2_pos.y = dot(gl_LightSource[1].position.xyz, bitangent);
	light2_pos.z = dot(gl_LightSource[1].position.xyz, normal);
  
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	float step_size = 0.2;
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * gl_Vertex;
	ProjShadow2 = gl_TextureMatrix[0] * (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,5.0*step_size,0.0));
	ProjShadow3 = gl_TextureMatrix[0] * (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,4.0*step_size,0.0));
	ProjShadow4 = gl_TextureMatrix[0] * (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,3.0*step_size,0.0));
	ProjShadow5 = gl_TextureMatrix[0] * (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,2.0*step_size,0.0));
	ProjShadow6 = gl_TextureMatrix[0] * (gl_ModelViewMatrix * gl_Vertex - vec4(0.0,0.0,1.0*step_size,0.0));
	
	gl_FrontColor = gl_Color;
} 
