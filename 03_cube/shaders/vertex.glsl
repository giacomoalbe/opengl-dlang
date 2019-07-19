#version 130

in vec4 vPosition;

uniform mat4 rotation;

void main() {
  gl_Position = rotation * vPosition;
}
