#version 330 core
out vec4 FragColor;

//uniform float utime;
in vec3 v_color;

void main() {
  //float intensity = sin(utime);
  //vec3 color = vec3(intensity, intensity / 4, 1.0 - intensity);
  FragColor = vec4(v_color, 1.0);
}
