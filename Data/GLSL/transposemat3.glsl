mat3 transposeMat3(const mat3 matrix) {
	mat3 temp;
	temp[0][0] = matrix[0][0];
	temp[0][1] = matrix[1][0];
	temp[0][2] = matrix[2][0];
	temp[1][0] = matrix[0][1];
	temp[1][1] = matrix[1][1];
	temp[1][2] = matrix[2][1];
	temp[2][0] = matrix[0][2];
	temp[2][1] = matrix[1][2];
	temp[2][2] = matrix[2][2];
	return temp;
}

