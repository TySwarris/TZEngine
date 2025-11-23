#version 330 core
out vec4 FragColor;

//uniform float utime;
in vec3 ourcolor;

void main() {
  //float intensity = sin(utime);
  //vec3 color = vec3(intensity, intensity / 4, 1.0 - intensity);
  FragColor = vec4(ourcolor, 1.0);
}
