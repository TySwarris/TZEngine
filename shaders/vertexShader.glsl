#version 330 core
layout(location = 0) in vec3 apos; // the position variable has attribute position 0
layout(location = 1) in vec3 acolor; // the color variable has attribute position 1

out vec3 ourcolor; // output a color to the fragment shader

void main() {
  gl_Position = vec4(apos, 1.0);
  ourcolor = acolor; // set ourcolor to the input color we got from the vertex data
}
