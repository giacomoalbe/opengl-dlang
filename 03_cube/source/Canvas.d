import std;
import std.conv;
import std.stdio;
import std.string;

import gl3n.math;
import gl3n.util;
import gl3n.linalg;

import gdk.GLContext;
import gdk.Event;

import gtk.Widget;
import gtk.GLArea;
import glib.Timeout;

import glcore;
import imaged;

import ShaderProgram;

struct Triangle {
  vec4[] vertices;
  vec3 color;
}

mat4 rotateZ(int degAngle) {
  mat4 r = mat4.identity();

  float radAngle = PI_180 * degAngle;

  r[0][0] = cos(radAngle);
  r[0][1] = r[1][0] = sin(radAngle);
  r[1][1] = -r[0][0];

  return r;
}

class Canvas : GLArea {
  GLuint[] vaos, vbos;
  ShaderProgram shaderProgram;
  int width, height;

  float[] vertices;

  Triangle[] triangles;

  vec4[] points = [
    vec4(-0.5,-0.5,0.5,1),
    vec4(-0.5,0.5,0.5,1),
    vec4(0.5,0.5,0.5,1),
    vec4(0.5,-0.5,0.5,1),
    vec4(-0.5,-0.5,-0.5,1),
    vec4(-0.5,0.5,-0.5,1),
    vec4(0.5,0.5,-0.5,1),
    vec4(0.5,-0.5,-0.5,1)
  ];

  vec3[] mainColors = [
    vec3(1.0f, 0, 0),
    vec3(0, 1.0f, 0),
    vec3(0, 0, 1.0f),
    vec3(1.0f, 1.0f, 0),
    vec3(0, 1.0f, 1.0f),
    vec3(1.0f, 0, 1.0f),
  ];

  vec4[] colors, cubePoints;
  Timeout timeout;
  mat4 rotation;
  int currentAngle;

  this() {
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);

    setHasDepthBuffer(true);
    setAutoRender(true);

    setSizeRequest(300,300);
    setHexpand(true);
    setVexpand(true);

    addOnRender(&render);
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);
    addOnResize(&resize);
    addOnButtonPress(&click);
    addOnMotionNotify(&hover);

    timeout = new Timeout(1000 / 60, &timeoutCallback);

    rotation = mat4.xrotation(radians(45)) * mat4.yrotation(radians(60));

    currentAngle = 0;

    showAll();
  }

  bool timeoutCallback() {
    rotation = mat4.xrotation(radians(45)) * mat4.yrotation(radians(currentAngle));
    currentAngle += 1;

    this.queueDraw();
    return true;
  }

  bool click(Event event, Widget widget) {
    return true;
  }

  bool hover(Event event, Widget widget) {
    return true;
  }

  void resize(int newWidth, int newHeight, GLArea area) {
    this.width = newWidth;
    this.height = newHeight;
  }

  void realize(Widget) {
    makeCurrent();
    initGraphics();
  }

  void unrealize(Widget) {
    makeCurrent();

    foreach(vboId; this.vbos) {
      glDeleteBuffers(1, &vboId);
    }

    foreach(vaoId; this.vaos) {
      glDeleteVertexArrays(1, &vaoId);
    }
  }

  bool render(GLContext ctx, GLArea a) {
    makeCurrent();

    drawCanvas();

    glFlush();

    return true;
  }

  void drawCanvas() {
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    this.linkGeometry();

    this.shaderProgram.use();

    this.shaderProgram.setMatrix("rotation", this.rotation);

    foreach(i, Triangle tris; triangles) {
      this.shaderProgram.setFloat("color", [tris.color.r, tris.color.g, tris.color.b]);
      glDrawArrays(GL_TRIANGLES, to!int(3 * i), 3);
    }
  }

  void tris(int a, int b, int c, vec3 color) {
    Triangle newTris;

    newTris.color = color;
    newTris.vertices ~= points[a];
    newTris.vertices ~= points[b];
    newTris.vertices ~= points[c];

    triangles ~= newTris;
  }

  void quad(int a, int b, int c, int d, vec3 color) {
    tris(a, b, c, color);
    tris(a, c, d, color);
  }

  void generateColorCube() {
    quad(0,3,2,1, mainColors[0]);
    quad(2,3,7,6, mainColors[1]);
    quad(3,0,4,7, mainColors[2]);
    quad(1,2,6,5, mainColors[3]);
    quad(4,5,6,7, mainColors[4]);
    quad(5,4,0,1, mainColors[5]);
  }

  void generateGeomtry() {
    generateColorCube();
  }

  void linkGeometry() {
    this.vertices = [];

    foreach(Triangle tris; triangles) {
      foreach(vec4 vertex; tris.vertices) {
        vertices ~= vertex.x;
        vertices ~= vertex.y;
        vertices ~= vertex.z;
      }
    }

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);
  }

  void initGraphics() {
    this.shaderProgram = new ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl");

    GLuint vao, vbo, ebo;

    // VAO
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);

    // VBO
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);

    this.vaos ~= vao;
    this.vbos ~= vbo;

    this.generateGeomtry();

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);

    GLuint loc = glGetAttribLocation(this.shaderProgram.id, "vPosition");
    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 3, GL_FLOAT, GL_FALSE, 0, cast(void*) 0);

    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);
    glBindVertexArray(this.vaos[0]);
  }
}
