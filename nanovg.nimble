# Package

version       = "0.3.4"
author        = "John Novak <john@johnnovak.net>"
description   = "Nim wrapper for the NanoVG vector graphics library for OpenGL"
license       = "MIT"

skipDirs = @["doc", "examples"]

srcDir = "src"

# Dependencies

requires "nim >= 1.6.4"

let
  examples_common = @[
    "multiwindow.nim",
    "pixelperfect.nim",
  ]
  examples_gl2 = @[
    "example_gl2.nim",
    "simple_gl2.nim",
  ] & examples_common
  examples_gl3 = @[
    "example_gl3.nim",
    "simple_gl3.nim",
    "example_fbo.nim",
  ] & examples_common
  compileBaseCmd = "compile -d:glfwStaticLib -d:demoMSAA "


taskrequires "examplesGL2", "glfw >= 3.4.0.4"
taskrequires "examplesGL3", "glfw >= 3.4.0.4"
taskrequires "examplesGL2Debug", "glfw >= 3.4.0.4"
taskrequires "examplesGL3Debug", "glfw >= 3.4.0.4"

task examplesGL2Debug, "Compiles the examples (GL2, debug mode)":
  for example in examples_gl2:
    selfExec compileBaseCmd & "-d:debug -d:nvgGL2 examples/" & example

task examplesGL3Debug, "Compiles the examples (GL3, debug mode)":
  for example in examples_gl3:
    selfExec compileBaseCmd & "-d:debug -d:nvgGL3 examples/" & example

task examplesGL2, "Compiles the examples (GL2, release mode)":
  for example in examples_gl2:
    selfExec compileBaseCmd & "-d:release -d:nvgGL2 examples/" & example

task examplesGL3, "Compiles the examples (GL3, release mode)":
  for example in examples_gl3:
    selfExec compileBaseCmd & "-d:release -d:nvgGL3 examples/" & example

task docgen, "Generate HTML documentation":
  selfExec "doc -d:nvgGL3 -o:doc/nanovg.html nanovg"
  selfExec "doc -d:nvgGL3 -o:doc/wrapper.html nanovg/wrapper"
