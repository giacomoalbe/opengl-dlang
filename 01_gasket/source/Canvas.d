import std;
import std.conv;
import std.stdio;
import std.string;
import std.random;

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
  int width, height, NUM_POINTS, NUM_RECURSION;

  float[] vertices, colors;

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

    readConfig();

    showAll();
  }

  void readConfig() {
    File fileConfig = File("canvas.conf", "r");

    string[] configItem;

    while (!fileConfig.eof) {
      string configString = fileConfig.readln();

      if (configString != "") {
        configItem = configString.strip().split(":");

        writeln(configItem);

        switch (configItem[0]) {
          case "NUM_POINTS":
            this.NUM_POINTS = to!int(configItem[1]);
            break;

          case "NUM_RECURSION":
            this.NUM_RECURSION = to!int(configItem[1]);
            break;

          default:
            writefln("Configurazione %s non riconosciuta", configItem[0]);
        }
      }
    }

    fileConfig.close();
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
    glBindVertexArray(this.vaos[0]);

    this.shaderProgram.use();

    //glDrawArrays(GL_TRIANGLES, 0, pow(3, this.NUM_RECURSION + 1));
    //glDrawArrays(GL_POINTS, 0, 3 * this.NUM_POINTS);
    glDrawArrays(GL_TRIANGLES, 0, pow(6, this.NUM_RECURSION + 1));
  }

  void randomSierpinski2D() {
    vec2[] points;

    vec2[] vertices = [
      vec2(0.0f, 1.0f),
      vec2(1.0f, -1.0f),
      vec2(-1.0f, -1.0f),
    ];

    vec2 prevPoint = vec2(0.25, 0.50);

    points ~= prevPoint;

    for (int k=1; k < NUM_POINTS; k++) {
      int j = uniform(0, 3);

      prevPoint = (prevPoint + vertices[j]) / 2.0;
      points ~= prevPoint;
    }

    foreach(vec2 point; points) {
      this.vertices ~= point.x;
      this.vertices ~= point.y;
    }
  }

  void randomSierpinski3D() {
    vec3[] points;

    vec3[] vertices = [
      vec3(0, 1, -1),
      vec3(-1, -1, -1),
      vec3(1, -1, -1),
      vec3(0, 0, 1),
    ];

    vec3 nextPoint;
    vec3 prevPoint = vec3(0,0,0);

    points ~= prevPoint;

    for (int k=1; k < this.NUM_POINTS; k++) {
      int j = uniform(0, 4);

      prevPoint = (prevPoint + vertices[j]) / 2.0;
      points ~= prevPoint;
    }

    foreach(vec3 point; points) {
      this.vertices ~= point.x;
      this.vertices ~= point.y;
      this.vertices ~= point.z;
    }
  }

  void recursiveSierpinsky2D() {
    this.vertices = [];

    vec2[] points;
    vec2[] vertices = [
      vec2(0.0, 1.0),
      vec2(1.0, -1.0),
      vec2(-1.0,-1.0),
    ];

    void drawTriangle(vec2 a, vec2 b, vec2 c) {
      points ~= a;
      points ~= b;
      points ~= c;
    }

    void divideTriangle(vec2 a, vec2 b, vec2 c, int num_recursion) {
      if (num_recursion > 0) {
        // Compute midpoints
        vec2 ab = (a + b) / 2.0;
        vec2 ac = (a + c) / 2.0;
        vec2 bc = (b + c) / 2.0;

        divideTriangle(a, ab, ac, num_recursion - 1);
        divideTriangle(c, ac, bc, num_recursion - 1);
        divideTriangle(b, bc, ab, num_recursion - 1);
      } else {
        drawTriangle(a, b, c);
      }
    }

    divideTriangle(vertices[0], vertices[1], vertices[2], this.NUM_RECURSION);

    foreach(vec2 point; points) {
      this.vertices ~= point.x;
      this.vertices ~= point.y;
    }
  }

  void recursiveSierpinsky3D() {
    this.vertices = [];

    int color_index = 0;

    vec3[] points;
    vec3[] vertices = [
      vec3(1, -1, -1),
      vec3(-1, -1, -1),
      vec3(0, 1, -1),
      vec3(0, 0, 1),
    ];
    vec3[] colors;
    vec3[] base_colors = [
      vec3(1, 0, 0),
      vec3(0, 1, 0),
      vec3(0, 0, 1),
      vec3(0, 0, 0),
    ];

    void drawTriangle(vec3 a, vec3 b, vec3 c) {
      points ~= a;
      points ~= b;
      points ~= c;

      colors ~= base_colors[color_index];
      colors ~= base_colors[color_index];
      colors ~= base_colors[color_index];

      color_index = (color_index + 1) % 4;
    }

    void drawTetra(vec3 a, vec3 b, vec3 c, vec3 d) {
      drawTriangle(a, b, c);
      drawTriangle(a, c, d);
      drawTriangle(a, d, b);
      drawTriangle(b, d, c);
    }

    void divideTetra(vec3 a, vec3 b, vec3 c, vec3 d, int num_recursion) {
      if (num_recursion > 0) {
        // Compute midpoints
        vec3 ab = (a + b) / 2.0;
        vec3 ac = (a + c) / 2.0;
        vec3 ad = (a + d) / 2.0;
        vec3 bc = (b + c) / 2.0;
        vec3 cd = (c + d) / 2.0;
        vec3 bd = (b + d) / 2.0;

        divideTetra( a, ab, ac, ad, num_recursion - 1);
        divideTetra(ab,  b, bc, bd, num_recursion - 1);
        divideTetra(ac, bc,  c, cd, num_recursion - 1);
        divideTetra(ad, bd, cd,  d, num_recursion - 1);
      } else {
        drawTetra(a, b, c, d);
      }
    }

    divideTetra(vertices[0], vertices[1], vertices[2], vertices[3], this.NUM_RECURSION);

    foreach(vec3 point; points) {
      this.vertices ~= point.x;
      this.vertices ~= point.y;
      this.vertices ~= point.z;
    }

    foreach(vec3 color; colors) {
      this.colors ~= color.r;
      this.colors ~= color.g;
      this.colors ~= color.b;
    }
  }

  void generateGeomtry() {
    //randomSierpinski2D();
    //recursiveSierpinsky2D();
    //randomSierpinski3D();
    recursiveSierpinsky3D();
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

    glBufferData(
        GL_ARRAY_BUFFER,
        (this.vertices.length + this.colors.length) * float.sizeof,
        null,
        GL_STATIC_DRAW
    );

    glBufferSubData(
        GL_ARRAY_BUFFER,
        0,
        this.vertices.length * float.sizeof,
        this.vertices.ptr
    );

    glBufferSubData(
        GL_ARRAY_BUFFER,
        this.vertices.length * float.sizeof,
        this.colors.length * float.sizeof,
        this.colors.ptr
    );

    GLuint loc = glGetAttribLocation(this.shaderProgram.id, "vPosition");
    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 3, GL_FLOAT, GL_FALSE, 0, cast(void*) 0);

    GLuint loc2 = glGetAttribLocation(this.shaderProgram.id, "vColor");
    glEnableVertexAttribArray(loc2);
    glVertexAttribPointer(
        loc2, 3,
        GL_FLOAT, GL_FALSE,
        0,
        cast(void*) (this.vertices.length * float.sizeof)
    );

    glBindBuffer(GL_ARRAY_BUFFER, this.vbos[0]);
    glBindVertexArray(this.vaos[0]);
  }
}
