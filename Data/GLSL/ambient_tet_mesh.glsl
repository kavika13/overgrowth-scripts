
float Determinant4x4( vec4 v0,
                      vec4 v1,
                      vec4 v2,
                      vec4 v3 )
{
    float det = v0[3]*v1[2]*v2[1]*v3[0] - v0[2]*v1[3]*v2[1]*v3[0] -
                v0[3]*v1[1]*v2[2]*v3[0] + v0[1]*v1[3]*v2[2]*v3[0] +

                v0[2]*v1[1]*v2[3]*v3[0] - v0[1]*v1[2]*v2[3]*v3[0] -
                v0[3]*v1[2]*v2[0]*v3[1] + v0[2]*v1[3]*v2[0]*v3[1] +

                v0[3]*v1[0]*v2[2]*v3[1] - v0[0]*v1[3]*v2[2]*v3[1] -
                v0[2]*v1[0]*v2[3]*v3[1] + v0[0]*v1[2]*v2[3]*v3[1] +

                v0[3]*v1[1]*v2[0]*v3[2] - v0[1]*v1[3]*v2[0]*v3[2] -
                v0[3]*v1[0]*v2[1]*v3[2] + v0[0]*v1[3]*v2[1]*v3[2] +

                v0[1]*v1[0]*v2[3]*v3[2] - v0[0]*v1[1]*v2[3]*v3[2] -
                v0[2]*v1[1]*v2[0]*v3[3] + v0[1]*v1[2]*v2[0]*v3[3] +

                v0[2]*v1[0]*v2[1]*v3[3] - v0[0]*v1[2]*v2[1]*v3[3] -
                v0[1]*v1[0]*v2[2]*v3[3] + v0[0]*v1[1]*v2[2]*v3[3];
    return det;
}
 
vec4 GetBarycentricCoordinate( vec3 v0_,
                               vec3 v1_,
                               vec3 v2_,
                               vec3 v3_,
                               vec3 p0_)
{
    vec4 v0 = vec4(v0_, 1.0);
    vec4 v1 = vec4(v1_, 1.0);
    vec4 v2 = vec4(v2_, 1.0);
    vec4 v3 = vec4(v3_, 1.0);
    vec4 p0 = vec4(p0_, 1.0);
    vec4 barycentricCoord;
    float det0 = Determinant4x4(v0, v1, v2, v3);
    float det1 = Determinant4x4(p0, v1, v2, v3);
    float det2 = Determinant4x4(v0, p0, v2, v3);
    float det3 = Determinant4x4(v0, v1, p0, v3);
    float det4 = Determinant4x4(v0, v1, v2, p0);
    barycentricCoord[0] = (det1/det0);
    barycentricCoord[1] = (det2/det0);
    barycentricCoord[2] = (det3/det0);
    barycentricCoord[3] = (det4/det0);
    return barycentricCoord;
}

// tetrahedron points (128)
// tetrahedron neighbor ids (128)

// tetrahedron render info: (128*3)
//    1 bit per point (is valid point?)
//    red 5*4*6
//    green 5*4*6
//    blue 5*4*6

const uint NULL_TET = 4294967295u;

bool GetAmbientCube(in vec3 pos, int num_light_probes, in usamplerBuffer tet_buf, out vec3 ambient_cube_color[6], uint guess) {
    if(num_light_probes == 0){
        return false;
    }
    uint tet_guess = guess;
    int num_guess = 0;
    const int kMaxGuess = 20;
    while(tet_guess != NULL_TET && num_guess < kMaxGuess){
        ++num_guess;
        int index = int(tet_guess)*5;
        bool reject = false;
        uvec4 tet_point_bits = texelFetch(tet_buf, index);
        // 128 bits
        // 16 bits per axis for first point (16*3 = 48 bits)
        // 8 bits per axis for delta to other points (8*3*3 = 72 bits)
        const float scalar = 5.0;
        vec3 points[4];
        points[0][0] = (float(tet_point_bits[0] / 65536u) - 32767.0) / scalar;
        points[0][1] = (float(tet_point_bits[0] % 65536u) - 32767.0) / scalar;
        points[0][2] = (float(tet_point_bits[1] / 65536u) - 32767.0) / scalar;

        points[1][0] = points[0][0] + (float((tet_point_bits[1] % 65536u)/256u) - 127.0) / scalar;
        points[1][1] = points[0][1] + (float((tet_point_bits[1] % 65536u)%256u) - 127.0) / scalar;
        points[1][2] = points[0][2] + (float((tet_point_bits[2] / 65536u)/256u) - 127.0) / scalar;

        points[2][0] = points[0][0] + (float((tet_point_bits[2] / 65536u)%256u) - 127.0) / scalar;
        points[2][1] = points[0][1] + (float((tet_point_bits[2] % 65536u)/256u) - 127.0) / scalar;
        points[2][2] = points[0][2] + (float((tet_point_bits[2] % 65536u)%256u) - 127.0) / scalar;

        points[3][0] = points[0][0] + (float((tet_point_bits[3] / 65536u)/256u) - 127.0) / scalar;
        points[3][1] = points[0][1] + (float((tet_point_bits[3] / 65536u)%256u) - 127.0) / scalar;
        points[3][2] = points[0][2] + (float((tet_point_bits[3] % 65536u)/256u) - 127.0) / scalar;

        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = vec3(0.0);
        }
        vec4 bary_coords = 
            GetBarycentricCoordinate(points[0], points[1], 
                                     points[2], points[3], 
                                     pos);

        uvec4 neighbors = texelFetch(tet_buf, index+1);     
        if(bary_coords[0] < 0.0){
            tet_guess = neighbors[0];     
            continue; 
        } 
        if(bary_coords[1] < 0.0){
            tet_guess = neighbors[1];     
            continue; 
        } 
        if(bary_coords[2] < 0.0){
            tet_guess = neighbors[2];     
            continue; 
        } 
        if(bary_coords[3] < 0.0){
            tet_guess = neighbors[3];     
            continue; 
        }
        if(true){
            uvec4 red = texelFetch(tet_buf, index+2);
            uvec4 green = texelFetch(tet_buf, index+3);
            uvec4 blue = texelFetch(tet_buf, index+4);
            // Reduce/eliminate contribution from probes inside of walls
            // This loop is unrolled because otherwise there is a problem on Intel cards
            if((red[3]&1u) == 0u){
                bary_coords[0] *= 0.05;
            }
            if((red[3]&2u) == 0u){
                bary_coords[1] *= 0.05;
            }
            if((red[3]&4u) == 0u){
                bary_coords[2] *= 0.05;
            }
            if((red[3]&8u) == 0u){
                bary_coords[3] *= 0.05;
            }

            float total_bary_coords = bary_coords[0] + bary_coords[1] + bary_coords[2] + bary_coords[3];
            bary_coords /= total_bary_coords;

            ambient_cube_color[0][0] += float(red[0] >> 27)/31.0 * bary_coords[0];
            ambient_cube_color[1][0] += float((red[0] >> 22)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[2][0] += float((red[0] >> 17)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[3][0] += float((red[0] >> 12)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[4][0] += float((red[0] >> 7)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[5][0] += float((red[0] >> 2)&31u)/31.0 * bary_coords[0];

            ambient_cube_color[0][0] += float(((red[0] << 3)+(red[1] >> 29))&31u)/31.0 * bary_coords[1];
            ambient_cube_color[1][0] += float((red[1] >> 24)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[2][0] += float((red[1] >> 19)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[3][0] += float((red[1] >> 14)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[4][0] += float((red[1] >> 9)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[5][0] += float((red[1] >> 4)&31u)/31.0 * bary_coords[1];

            ambient_cube_color[0][0] += float(((red[1] << 1)+(red[2] >> 31))&31u)/31.0 * bary_coords[2];
            ambient_cube_color[1][0] += float((red[2] >> 26)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[2][0] += float((red[2] >> 21)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[3][0] += float((red[2] >> 16)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[4][0] += float((red[2] >> 11)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[5][0] += float((red[2] >> 6)&31u)/31.0 * bary_coords[2];

            ambient_cube_color[0][0] += float((red[2] >> 1)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[1][0] += float(((red[2] << 4)+(red[3] >> 28))&31u)/31.0 * bary_coords[3];
            ambient_cube_color[2][0] += float((red[3] >> 23)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[3][0] += float((red[3] >> 18)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[4][0] += float((red[3] >> 13)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[5][0] += float((red[3] >> 8)&31u)/31.0 * bary_coords[3];


            ambient_cube_color[0][1] += float(green[0] >> 27)/31.0 * bary_coords[0];
            ambient_cube_color[1][1] += float((green[0] >> 22)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[2][1] += float((green[0] >> 17)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[3][1] += float((green[0] >> 12)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[4][1] += float((green[0] >> 7)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[5][1] += float((green[0] >> 2)&31u)/31.0 * bary_coords[0];

            ambient_cube_color[0][1] += float(((green[0] << 3)+(green[1] >> 29))&31u)/31.0 * bary_coords[1];
            ambient_cube_color[1][1] += float((green[1] >> 24)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[2][1] += float((green[1] >> 19)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[3][1] += float((green[1] >> 14)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[4][1] += float((green[1] >> 9)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[5][1] += float((green[1] >> 4)&31u)/31.0 * bary_coords[1];

            ambient_cube_color[0][1] += float(((green[1] << 1)+(green[2] >> 31))&31u)/31.0 * bary_coords[2];
            ambient_cube_color[1][1] += float((green[2] >> 26)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[2][1] += float((green[2] >> 21)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[3][1] += float((green[2] >> 16)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[4][1] += float((green[2] >> 11)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[5][1] += float((green[2] >> 6)&31u)/31.0 * bary_coords[2];

            ambient_cube_color[0][1] += float((green[2] >> 1)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[1][1] += float(((green[2] << 4)+(green[3] >> 28))&31u)/31.0 * bary_coords[3];
            ambient_cube_color[2][1] += float((green[3] >> 23)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[3][1] += float((green[3] >> 18)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[4][1] += float((green[3] >> 13)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[5][1] += float((green[3] >> 8)&31u)/31.0 * bary_coords[3];


            ambient_cube_color[0][2] += float(blue[0] >> 27)/31.0 * bary_coords[0];
            ambient_cube_color[1][2] += float((blue[0] >> 22)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[2][2] += float((blue[0] >> 17)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[3][2] += float((blue[0] >> 12)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[4][2] += float((blue[0] >> 7)&31u)/31.0 * bary_coords[0];
            ambient_cube_color[5][2] += float((blue[0] >> 2)&31u)/31.0 * bary_coords[0];

            ambient_cube_color[0][2] += float(((blue[0] << 3)+(blue[1] >> 29))&31u)/31.0 * bary_coords[1];
            ambient_cube_color[1][2] += float((blue[1] >> 24)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[2][2] += float((blue[1] >> 19)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[3][2] += float((blue[1] >> 14)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[4][2] += float((blue[1] >> 9)&31u)/31.0 * bary_coords[1];
            ambient_cube_color[5][2] += float((blue[1] >> 4)&31u)/31.0 * bary_coords[1];

            ambient_cube_color[0][2] += float(((blue[1] << 1)+(blue[2] >> 31))&31u)/31.0 * bary_coords[2];
            ambient_cube_color[1][2] += float((blue[2] >> 26)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[2][2] += float((blue[2] >> 21)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[3][2] += float((blue[2] >> 16)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[4][2] += float((blue[2] >> 11)&31u)/31.0 * bary_coords[2];
            ambient_cube_color[5][2] += float((blue[2] >> 6)&31u)/31.0 * bary_coords[2];

            ambient_cube_color[0][2] += float((blue[2] >> 1)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[1][2] += float(((blue[2] << 4)+(blue[3] >> 28))&31u)/31.0 * bary_coords[3];
            ambient_cube_color[2][2] += float((blue[3] >> 23)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[3][2] += float((blue[3] >> 18)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[4][2] += float((blue[3] >> 13)&31u)/31.0 * bary_coords[3];
            ambient_cube_color[5][2] += float((blue[3] >> 8)&31u)/31.0 * bary_coords[3];

            return true;
        }
    }
    return false;
}

vec3 SampleAmbientCube(in vec3 ambient_cube_color[6], in vec3 vec){
    float sum = abs(vec[0]) + abs(vec[1]) + abs(vec[2]);
    vec3 temp_vert = vec / vec3(sum);
    vec3 total_cube = vec3(0.0);
    total_cube += ambient_cube_color[0+int(temp_vert.x<0)] * vec3(abs(temp_vert.x));
    total_cube += ambient_cube_color[2+int(temp_vert.y<0)] * vec3(abs(temp_vert.y));
    total_cube += ambient_cube_color[4+int(temp_vert.z<0)] * vec3(abs(temp_vert.z));
    return total_cube;
}