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

import glcore;
import imaged;

import ShaderProgram;

class Canvas : GLArea {
  GLuint[] vaos, vbos;
  ShaderProgram shaderProgram;
  int width, height;

  float[] vertices;

  this() {
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

    showAll();
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
    glClear(GL_COLOR_BUFFER_BIT);
    glBindVertexArray(this.vaos[0]);

    this.shaderProgram.use();

    glDrawArrays(GL_TRIANGLES, 0, 3);
  }

  void generateGeomtry() {
    this.vertices = [
      0.0f, 0.5f,
      0.5f, -0.5f,
      -0.5f, -0.5f,
    ];
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
    glVertexAttribPointer(loc, 2, GL_FLOAT, GL_FALSE, 0, cast(void*) 0);

    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);
    glBindVertexArray(this.vaos[0]);
  }
}
