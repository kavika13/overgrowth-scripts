uniform mat4 matrix;
void main() {    
    gl_Position = matrix * gl_Vertex;
}