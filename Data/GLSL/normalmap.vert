uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;

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
  
    light2_pos.x = dot(gl_LightSource[1].position.xyz, temp_tangent);
	light2_pos.y = dot(gl_LightSource[1].position.xyz, bitangent);
	light2_pos.z = dot(gl_LightSource[1].position.xyz, normal);
  
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
