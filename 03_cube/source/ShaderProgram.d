import std;
import std.conv;
import std.stdio;
import std.string;

import gl3n.math;
import gl3n.util;
import gl3n.linalg;

import glcore;
import imaged;

struct Texture {
  GLuint id;
  GLuint unit;
}

class ShaderProgram {
  GLint id;
  GLuint[string] shaders;
  Texture[] textures;

  this(string vertexShaderPath, string fragmentShaderPath) {
    File vertexShaderFile = File(vertexShaderPath);
    File fragmentShaderFile = File(fragmentShaderPath);

    string vertexShaderFileContent = "";
    string fragmentShaderFileContent = "";

    while (!vertexShaderFile.eof()) {
      vertexShaderFileContent ~= vertexShaderFile.readln();
    }

    while (!fragmentShaderFile.eof()) {
      fragmentShaderFileContent ~= fragmentShaderFile.readln();
    }

    vertexShaderFile.close();
    fragmentShaderFile.close();

    const(char)* vertexShaderSrc = vertexShaderFileContent.ptr;
    const(char)* fragmentShaderSrc = fragmentShaderFileContent.ptr;

    this.shaders["vertex"] = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(shaders["vertex"], 1, &vertexShaderSrc, null);
    glCompileShader(shaders["vertex"]);

    GLchar[] infoLog = new GLchar[512];
    int success;

    glGetShaderiv(shaders["vertex"], GL_COMPILE_STATUS, &success);

    if (!success) {
      writeln("VERTEX:COMPILE:ERROR");
      glGetShaderInfoLog(shaders["vertex"], 512, cast(int*)0, infoLog.ptr);
      writeln(infoLog);
    }

    this.shaders["fragment"] = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(shaders["fragment"], 1, &fragmentShaderSrc, null);
    glCompileShader(shaders["fragment"]);

    glGetShaderiv(shaders["fragment"], GL_COMPILE_STATUS, &success);

    if (!success) {
      writeln("FRAGMENT:COMPILE:ERROR");
      glGetShaderInfoLog(shaders["fragment"], 512, cast(int*)0, infoLog.ptr);
      writeln(infoLog);
    }

    this.id = glCreateProgram();


    glAttachShader(this.id, this.shaders["vertex"]);
    glAttachShader(this.id, this.shaders["fragment"]);

    glLinkProgram(this.id);
    glUseProgram(this.id);
  }

  ~this() {
    writeln("Deleting program: ", this.id);
    glDeleteProgram(this.id);

    foreach(shaderName, shaderId; this.shaders) {
      writeln("Deleting shader: ", shaderName);
      glDeleteShader(shaderId);
    }
  }

  void use() {
    glUseProgram(id);
  }

  void setFloat(string uniformName, float[] floats) {
    int uniformNameId = glGetUniformLocation(this.id, uniformName.toStringz);

    if (uniformNameId > -1) {
      switch (floats.length) {
        case 1:
          glUniform1f(uniformNameId, floats[0]);
          break;
        case 2:
          glUniform2f(uniformNameId, floats[0], floats[1]);
          break;
        case 3:
          glUniform3f(uniformNameId, floats[0], floats[1], floats[2]);
          break;
        case 4:
          glUniform4f(uniformNameId, floats[0], floats[1], floats[2], floats[3]);
          break;
        default:
          break;
      }
    }
  }

  void setInt(string uniformName, int value) {
    int uniformNameId = glGetUniformLocation(this.id, uniformName.toStringz);

    if (uniformNameId > -1) {
      glUniform1i(uniformNameId, value);
    }
  }

  void generateTexture(string texturePath, GLuint textureUnit = 0) {
    IMGError error;
    GLuint texId;

    glGenTextures(1, &texId);
    glActiveTexture(GL_TEXTURE0 + textureUnit);
    glBindTexture(GL_TEXTURE_2D, texId);

    Texture newText = {
      id: texId,
      unit: GL_TEXTURE0 + textureUnit
    };

    this.textures ~= newText;

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    Image textureImg = load(texturePath, error);

    if (error.code) {
      writeln("Error in reading/parsing texture");
    } else {
      writefln("Generating texture with: W: %d H: %d", textureImg.width, textureImg.height);

      string imageFileExt = texturePath.split(".")[1];

      glTexImage2D(
          GL_TEXTURE_2D,
          0, // mipmap level
          GL_RGB,
          textureImg.width,
          textureImg.height,
          0, // legacy stuff
          imageFileExt == "png" ? GL_RGBA : GL_RGB, // format for texture storage
          GL_UNSIGNED_BYTE, // format of the stored texture data
          textureImg.pixels.ptr
        );

      // Generate mipmap for the current bound texture buffer
      glGenerateMipmap(GL_TEXTURE_2D);
    }
  }

  void setTransform(mat4 transform) {
    auto transformUniformId = glGetUniformLocation(this.id, "transform");
    glUniformMatrix4fv(transformUniformId, 1, GL_FALSE, transform.value_ptr);
  }

  void setTransformationMatrix(mat4 p, mat4 v, mat4 m) {
    auto transformUniformId = glGetUniformLocation(this.id, "projection");
    glUniformMatrix4fv(transformUniformId, 1, GL_FALSE, p.value_ptr);

    transformUniformId = glGetUniformLocation(this.id, "view");
    glUniformMatrix4fv(transformUniformId, 1, GL_FALSE, v.value_ptr);

    transformUniformId = glGetUniformLocation(this.id, "model");
    glUniformMatrix4fv(transformUniformId, 1, GL_FALSE, m.value_ptr);
  }

  void renderTexture() {
    foreach(i, tex; this.textures) {
      this.setInt("tex" ~ to!string(i), cast(int)i);

      glActiveTexture(tex.unit);
      glBindTexture(GL_TEXTURE_2D, tex.id);
    }
  }
}
