mat4 GetPseudoInstanceMat4() {
	return mat4(gl_MultiTexCoord4,
				gl_MultiTexCoord5,
				gl_MultiTexCoord6,
				gl_MultiTexCoord7);
}

mat3 GetPseudoInstanceMat3() {
	return mat3(gl_MultiTexCoord4.xyz,
				gl_MultiTexCoord5.xyz,
				gl_MultiTexCoord6.xyz);
}