# template.nim

import std/strformat
import glfw

import glad/gl
import nanovg


type
  App = ref object
    win: Window
    vg: NVGcontext
    premult: bool = false
    vsync: bool = true


proc `$`(app: App): string =
  fmt"<App premult: {app.premult} vsync: {app.vsync}>"


proc keyCb(
  win: Window,
  key: Key,
  scanCode: int32,
  action: KeyAction,
  modKeys: set[ModifierKey]
) =
  if action != kaDown: return
  var app = cast[ptr App](win.getUserPointer())

  case key
    of keyEscape: win.shouldClose = true
    of keyP: app.premult = not app.premult
    of keyV: app.vsync = not app.vsync
    else: return


proc renderMain(
  app: App,
  mx: float = 0,
  my: float = 0,
  width: float = 100,
  height: float = 100,
  delta: float = 0.0
) =
  app.vg.fillColor(rgb(200, 0, 200))
  app.vg.ellipse(100, 100, 70, 70)
  app.vg.fill()


proc createWindow(
  width, height: int, title: string,
  resizable: bool = true,
  fullscreen: bool = false,
  transparent: bool = false,
  decorated: bool = true,
  msaa: int = 4
): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: width, h: height)
  cfg.title = title
  cfg.resizable = resizable
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.nMultiSamples = msaa.int32
  cfg.transparentFramebuffer = transparent
  cfg.decorated = decorated

  when not defined(windows):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)


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
    glViewport(0, 0, fbWidth, fbHeight)

    if app.premult:
      glClearColor(0, 0, 0, 0)
    else:
      glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    app.vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    app.renderMain(mx, my, winWidth.float, winHeight.float, dt)

    app.vg.endFrame()
    glfw.swapBuffers(app.win)

  # De-init
  nvgDeleteContext(app.vg)
  glfw.terminate()


proc newApp(): App =
  new(result)
  # Initialization
  glfw.initialize()

  var win = createWindow(800, 600, "Demo")
  win.keyCb = keyCb

  glfw.makeContextCurrent(win)
  result.win = win
  result.win.setUserPointer(result.addr)

  var flags = {nifStencilStrokes, nifDebug}
  when not defined(appMSAA): flags = flags + {nifAntialias}

  nvgInit(getProcAddress)
  result.vg = nvgCreateContext(flags)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"


proc main() =
  var app = newApp()
  app.mainLoop()


main()
