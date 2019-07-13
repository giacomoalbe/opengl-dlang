import std;
import std.math;
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

import glcore;
import imaged;

import ShaderProgram;

struct Triangle {
  float[] vertices;
  vec3 color;
}

class Canvas : GLArea {
  GLuint[] vaos, vbos;
  ShaderProgram shaderProgram;
  int width, height;
  int count;

  Triangle[] tris;
  float[] vertices;

  bool enableTrianglePaint;

  this() {
    setAutoRender(true);

    setSizeRequest(300,300);
    setHexpand(true);
    setVexpand(true);

    addOnRender(&render);
    addOnRealize(&realize);
    addOnUnrealize(&unrealize);
    addOnResize(&resize);
    addOnButtonPress(&mousePress);
    addOnButtonRelease(&mouseRelease);
    addOnMotionNotify(&mouseHover);

    count = 0;
    enableTrianglePaint = false;

    showAll();
  }

  bool mousePress(Event event, Widget widget) {
    this.enableTrianglePaint = true;
    return true;
  }

  bool mouseRelease(Event event, Widget widget) {
    this.tris = [];
    this.enableTrianglePaint = false;
    this.queueDraw();
    return true;
  }

  bool mouseHover(Event event, Widget widget) {
    if (this.enableTrianglePaint) {
      float l = 0.1;

      float x = (event.motion.x / (this.width / 2)) - 1.0;
      float y = ((this.height - event.motion.y) / (this.height / 2)) - 1.0;

      Triangle newTris;

      newTris.color = vec3(
          uniform(0.0f, 1.0f),
          uniform(0.0f, 1.0f),
          uniform(0.0f, 1.0f),
          );

      float halfWidth = l / 2;
      float halfHeight = sqrt(3.0f) / 4 * l;

      newTris.vertices ~= [x - halfWidth, y - halfHeight];
      newTris.vertices ~= [x,             y + halfHeight];
      newTris.vertices ~= [x + halfWidth, y - halfHeight];

      this.tris ~= newTris;

      this.queueDraw();

      return true;
    } else {
      return false;
    }
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
    generateGeomtry();
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

    return false;
  }

  void drawCanvas() {
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    this.linkGeometry();

    this.shaderProgram.use();

    foreach(i, ref triangle; tris) {
      this.shaderProgram.setFloat("color", [triangle.color.r, triangle.color.g, triangle.color.b]);
      glDrawArrays(GL_TRIANGLES, cast(int) (3 * i), 3);
    }
  }

  void linkGeometry() {
    this.vertices = [];

    foreach(Triangle triangle; this.tris) {
      this.vertices ~= triangle.vertices;
    }

    glBufferData(GL_ARRAY_BUFFER, this.vertices.length * float.sizeof, this.vertices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);

  }

  void generateGeomtry() {
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

    GLuint loc = glGetAttribLocation(this.shaderProgram.id, "vPosition");

    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 2, GL_FLOAT, GL_FALSE, 0, cast(void*) 0);
  }
}
