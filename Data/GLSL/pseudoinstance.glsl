mat4 GetPseudoInstanceMat4() {
	return mat4(gl_MultiTexCoord4.x,gl_MultiTexCoord5.x,gl_MultiTexCoord6.x,0.0,
				gl_MultiTexCoord4.y,gl_MultiTexCoord5.y,gl_MultiTexCoord6.y,0.0,
				gl_MultiTexCoord4.z,gl_MultiTexCoord5.z,gl_MultiTexCoord6.z,0.0,
				gl_MultiTexCoord4.a,gl_MultiTexCoord5.a,gl_MultiTexCoord6.a,1.0);
}

mat3 GetPseudoInstanceMat3() {
	return mat3(gl_MultiTexCoord4.x,gl_MultiTexCoord5.x,gl_MultiTexCoord6.x,
				gl_MultiTexCoord4.y,gl_MultiTexCoord5.y,gl_MultiTexCoord6.y,
				gl_MultiTexCoord4.z,gl_MultiTexCoord5.z,gl_MultiTexCoord6.z);
}

mat3 GetPseudoInstanceMat3Normalized() {
	return mat3(normalize(vec3(gl_MultiTexCoord4.x,gl_MultiTexCoord5.x,gl_MultiTexCoord6.x)),
				normalize(vec3(gl_MultiTexCoord4.y,gl_MultiTexCoord5.y,gl_MultiTexCoord6.y)),
				normalize(vec3(gl_MultiTexCoord4.z,gl_MultiTexCoord5.z,gl_MultiTexCoord6.z)));
}