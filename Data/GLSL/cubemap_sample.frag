#extension GL_ARB_shader_texture_lod : require

uniform vec3 sample_dir;
uniform samplerCube tex0;

void main() {
    gl_FragColor.xyz = textureCubeLod(tex0, sample_dir, 5.0);
    gl_FragColor.a = 1.0;
}