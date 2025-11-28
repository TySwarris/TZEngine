#version 330 core
layout(location = 0) in vec3 apos; // the position variable has attribute position 0
//
uniform vec3 u_color;
uniform mat4 u_mvpMatrix;

out vec3 v_color; // output a color to the fragment shader

void main() {
  gl_Position = u_mvpMatrix * vec4(apos, 1.0);
  v_color = u_color; // set ourcolor to the input color we got from the vertex data
}
