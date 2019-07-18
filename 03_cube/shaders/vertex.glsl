#version 130

in vec4 vPosition;

void main() {
  gl_Position = 0.5 * vPosition;
}
