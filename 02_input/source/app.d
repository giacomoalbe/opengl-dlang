import std.stdio;

import gdk.Event;
import gdk.GLContext;

import gtk.Main;

import Window;

void main(string[] args) {
  Main.init(args);

  int width = 800;
  int height = 600;

  auto win = new Window(width, height);

  Main.run();
}
