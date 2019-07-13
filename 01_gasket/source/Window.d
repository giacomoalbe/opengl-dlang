import std;

import gdk.Screen;

import gtk.MainWindow;
import gtk.Grid;
import gtk.Scale;
import gtk.Range;
import gtk.CssProvider;
import gtk.StyleContext;

import Canvas;

class Window : MainWindow {
  this(int width, int height) {
    super("GtkD OpenGL Template");

    Canvas canvas = new Canvas();

    add(canvas);

    setDefaultSize(width, height);
    showAll();
  }
}
