# template.nim

import std/[options, strformat]
import glm
import glfw
from glfw/wrapper import setWindowUserPointer, getWindowUserPointer
import glad/gl
import nanovg


type
  Vertex = object
    x, y: GLfloat
    r, g, b: GLfloat

var vertices: array[0..2, Vertex] = [
  Vertex(x: -0.6, y: -0.4, r: 1.0, g: 0.0, b: 0.0),
  Vertex(x:  0.6, y: -0.4, r: 0.0, g: 1.0, b: 0.0),
  Vertex(x:  0.0, y:  0.6, r: 0.0, g: 0.0, b: 1.0)
]

let vertexShaderText = """
#version 330
uniform mat4 MVP;
in vec3 vCol;
in vec2 vPos;
out vec3 color;

void main() {
  gl_Position = MVP * vec4(vPos, 0.0, 1.0);
  color = vCol;
}
"""

let fragmentShaderText = """
#version 330
in vec3 color;
out vec4 fragment;

void main() {
  fragment = vec4(color, 1.0);
}
"""

type
  App = ref object
    win: Window
    vg: NVGcontext
    premult: bool = false
    vsync: bool = true
    program: GLuint
    mvpLocation: GLuint
    vertexArray: GLuint

# ---------- Utility functions ----------

proc loadShaders(
  vertexShaderSrc, fragmentShaderSrc: string
): GLuint =
  var vertexShader = glCreateShader(GL_VERTEX_SHADER)
  var vertexShaderTextArr = [vertexShaderSrc.cstring]
  glShaderSource(vertexShader, GLsizei(1),
                 cast[cstringArray](vertexShaderTextArr.addr), nil)
  glCompileShader(vertexShader)

  var fragmentShaderTextArr = [fragmentShaderSrc.cstring]
  var fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragmentShader, 1,
                 cast[cstringArray](fragmentShaderTextArr.addr), nil)
  glCompileShader(fragmentShader)

  result = glCreateProgram()
  glAttachShader(result, vertexShader)
  glAttachShader(result, fragmentShader)
  glLinkProgram(result)


proc createWindow(
  width, height: int, title: string,
  resizable: bool = true,
  fullscreen: bool = false,
  transparent: bool = false,
  decorated: bool = true,
  msaa: int = 4
): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: width.int32, h: height.int32)
  cfg.title = title
  cfg.resizable = resizable
  cfg.bits = (r: some(8i32), g: some(8i32), b: some(8i32), a: some(8i32), stencil: some(8i32), depth: some(16i32))
  cfg.nMultiSamples = msaa.int32
  cfg.transparentFramebuffer = transparent
  cfg.decorated = decorated

  when not defined(windows):
    cfg.version = glv33
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)


# ---------- Event handlers ----------

proc `$`(app: App): string =
  fmt"<App premult: {app.premult} vsync: {app.vsync}>"


proc keyCb(
  win: Window,
  key: Key,
  scanCode: int32,
  action: KeyAction,
  modKeys: set[ModifierKey]
) =
  if action != kaDown:
    return

  var app = cast[ptr App](getWindowUserPointer(win.getHandle()))

  case key
    of keyEscape: win.shouldClose = true
    of keyP: app[].premult = not app[].premult
    of keyV: app[].vsync = not app[].vsync
    else: return


# ---------- Application object ----------

proc init3D(app: var App) =
  var vertexBuffer: GLuint
  glGenBuffers(1, vertexBuffer.addr)
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer)

  glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(sizeof(vertices)), vertices.addr,
               GL_STATIC_DRAW)

  app.program = loadShaders(vertexShaderText, fragmentShaderText)
  app.mvpLocation = cast[GLuint](glGetUniformLocation(app.program, "MVP"))
  var vposLocation = cast[GLuint](glGetAttribLocation(app.program, "vPos"))
  var vcolLocation = cast[GLuint](glGetAttribLocation(app.program, "vCol"))

  glGenVertexArrays(1, app.vertexArray.addr);
  glBindVertexArray(app.vertexArray);
  glEnableVertexAttribArray(vposLocation);
  glVertexAttribPointer(vposLocation, 2, cGL_FLOAT, false,
                        GLsizei(sizeof(Vertex)), cast[pointer](0))

  glEnableVertexAttribArray(vcolLocation)
  glVertexAttribPointer(vcolLocation, 3, cGL_FLOAT, false,
                        GLsizei(sizeof(Vertex)),
                        cast[pointer](sizeof(GLfloat) * 2));


proc newApp(): App =
  new(result)
  # Initialization
  glfw.initialize()

  var win = createWindow(800, 600, "Demo")
  win.keyCb = keyCb

  glfw.makeContextCurrent(win)

  var flags = {nifStencilStrokes, nifDebug}
  when not defined(appMSAA): flags = flags + {nifAntialias}

  nvgInit(getProcAddress)
  result.vg = nvgCreateContext(flags)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  result.init3D()
  setWindowUserPointer(win.getHandle(), result.addr)
  result.win = win


proc draw(
  app: App,
  mx: float = 0,
  my: float = 0,
  width: float = 100,
  height: float = 100,
  delta: float = 0.0
) =
  app.vg.fillColor(rgb(0, 200, 0))
  app.vg.ellipse(100, 100, 70, 70)
  app.vg.fill()
  let normal = vec3[GLfloat](0.0, 0.0, 1.0)

  var ratio = width / height

  glViewport(0, 0, GLsizei(width.int), GLsizei(height.int))
  glClear(GL_COLOR_BUFFER_BIT)

  var m = mat4x4[GLfloat](vec4(1'f32, 0'f32, 0'f32, 0'f32),
                          vec4(0'f32, 1'f32, 0'f32, 0'f32),
                          vec4(0'f32, 0'f32, 1'f32, 0'f32),
                          vec4(0'f32, 0'f32, 0'f32, 1'f32))
  m = m.rotate(getTime(), normal)
  var p = ortho[GLfloat](-ratio, ratio, -1.0, 1.0, 1.0, -1.0)
  var mvp = p * m

  glUseProgram(app.program)
  glUniformMatrix4fv(GLint(app.mvpLocation), 1, false, mvp.caddr);
  glBindVertexArray(app.vertexArray)
  glDrawArrays(GL_TRIANGLES, 0, 3)


proc mainLoop(app: App) =
  # Main loop
  setTime(0)
  var prevt = getTime()

  while not app.win.shouldClose:
    let
      t = getTime()
      dt = t - prevt

    prevt = t

    if app.vsync:
      glfw.swapInterval(1)
    else:
      glfw.swapInterval(0)

    let
      (mx, my) = app.win.cursorPos()
      (winWidth, winHeight) = app.win.size
      (fbWidth, fbHeight) = app.win.framebufferSize

      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth / winWidth

    # Handle events
    glfw.pollEvents()

    # Update and render
    glViewport(0, 0, fbWidth.GLsizei, fbHeight.GLsizei)

    if app.premult:
      glClearColor(0, 0, 0, 0)
    else:
      glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    app.vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    app.draw(mx, my, winWidth.float, winHeight.float, dt)

    app.vg.endFrame()
    glfw.swapBuffers(app.win)

  # De-init
  nvgDeleteContext(app.vg)
  glfw.terminate()


proc main() =
  var app = newApp()
  app.mainLoop()


main()
