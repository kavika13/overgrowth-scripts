#ifndef PSEUDO_INSTANCE_GLSL
#define PSEUDO_INSTANCE_GLSL

uniform mat4 modelMatrix;
uniform mat3 normalMatrix;

#ifdef VERTEX_SHADER

mat4 GetPseudoInstanceMat4() {
	return modelMatrix;
}
 
mat3 GetPseudoInstanceMat3() {
 	return normalMatrix;
}

mat3 GetPseudoInstanceMat3Normalized() {
	return normalMatrix;
}
#endif

#endif
