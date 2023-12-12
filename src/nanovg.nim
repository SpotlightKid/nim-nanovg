import math
import strformat

import nanovg/wrapper

# {{{ Exports

# Types
export wrapper.Font
export wrapper.Image
export wrapper.NoFont
export wrapper.NoImage
export wrapper.`==`

export wrapper.NVGContext
export wrapper.NVGInitFlag

export wrapper.BlendFactor
export wrapper.Bounds
export wrapper.Color
export wrapper.CompositeOperation
export wrapper.CompositeOperationState
export wrapper.GlyphPosition
export wrapper.HorizontalAlign
export wrapper.ImageFlags
export wrapper.LineCapJoin
export wrapper.Paint
export wrapper.PathWinding
export wrapper.Solidity
export wrapper.TransformMatrix
export wrapper.VerticalAlign

export wrapper.NVGLUFramebuffer

# Global
export wrapper.nvgDeleteContext

export wrapper.beginFrame
export wrapper.cancelFrame
export wrapper.endFrame

export wrapper.globalCompositeOperation
export wrapper.globalCompositeBlendFunc
export wrapper.globalCompositeBlendFuncSeparate

# Color utils
export wrapper.rgb
export wrapper.rgba
export wrapper.lerp
export wrapper.withAlpha
export wrapper.hsl
export wrapper.hsla

# State Handling
export wrapper.save
export wrapper.restore
export wrapper.reset

# Render styles
export wrapper.strokeColor
export wrapper.strokePaint
export wrapper.fillColor
export wrapper.fillPaint
export wrapper.strokeWidth
export wrapper.lineCap
export wrapper.lineJoin
export wrapper.globalAlpha

# Transforms
export wrapper.resetTransform
export wrapper.transform
export wrapper.translate
export wrapper.rotate
export wrapper.skewX
export wrapper.skewY
export wrapper.scale

# Images
export wrapper.updateImage
export wrapper.deleteImage

# Paints
export wrapper.linearGradient
export wrapper.boxGradient
export wrapper.radialGradient
export wrapper.imagePattern

# Scissoring
export wrapper.scissor
export wrapper.intersectScissor
export wrapper.resetScissor

# Paths
export wrapper.beginPath
export wrapper.moveTo
export wrapper.lineTo
export wrapper.bezierTo
export wrapper.quadTo
export wrapper.arcTo
export wrapper.closePath
export wrapper.pathWinding
export wrapper.arc
export wrapper.rect
export wrapper.roundedRect
export wrapper.ellipse
export wrapper.circle
export wrapper.fill
export wrapper.stroke

# Text
export wrapper.findFont
export wrapper.addFallbackFont
export wrapper.resetFallbackFonts
export wrapper.fontSize
export wrapper.fontBlur
export wrapper.textLetterSpacing
export wrapper.textLineHeight
export wrapper.fontFace
export wrapper.text
export wrapper.textBox

# Framebuffer
export wrapper.nvgluBindFramebuffer
export wrapper.nvgluDeleteFramebuffer

# }}}

type
  NVGError* = object of CatchableError
    message*: string

using ctx: NVGContext

# {{{ General functions

var g_gladInitialized = false

proc gladLoadGLLoader*(a: pointer): int {.cdecl, importc.}

proc nvgInit*(getProcAddress: pointer) =
  if not g_gladInitialized:
    if gladLoadGLLoader(getProcAddress) > 0:
      g_gladInitialized = true

  if not g_gladInitialized:
    raise newException(NVGError, "Failed to initialise NanoVG")


proc nvgCreateContext*(flags: set[NVGInitFlag] = {}): NVGContext =
  result = wrapper.nvgCreateContext(flags)
  if result == nil:
    raise newException(NVGError, "Failed to create NanoVG context")


template shapeAntiAlias*(ctx; enabled: bool) =
  shapeAntiAlias(ctx, enabled.cint)


proc nvgluCreateFramebuffer*(ctx; width: int, height: int,
                             imageFlags: set[ImageFlags]): NVGLUFramebuffer =

  nvgluCreateFramebuffer(ctx, width.cint, height.cint, cast[cint](imageFlags))

# }}}
# {{{ Transform functions

proc currentTransform*(ctx): TransformMatrix =
  nvgCurrentTransform(ctx, result.m[0].addr)

proc identity*(dst: var TransformMatrix) =
  nvgIdentity(dst.m[0].addr)

proc translate*(dst: var TransformMatrix, tx: float, ty: float) =
  nvgTranslate(dst.m[0].addr, tx.cfloat, ty.cfloat)

proc scale*(dst: var TransformMatrix, sx: float, sy: float) =
  nvgScale(dst.m[0].addr, sx.cfloat, sy.cfloat)

proc rotate*(dst: var TransformMatrix, angle: float) =
  nvgRotate(dst.m[0].addr, angle.cfloat)

proc skewX*(dst: var TransformMatrix, angle: float) =
  nvgSkewX(dst.m[0].addr, angle.cfloat)

proc skewY*(dst: var TransformMatrix, angle: float) =
  nvgSkewY(dst.m[0].addr, angle.cfloat)

proc multiply*(dst: var TransformMatrix, src: TransformMatrix) =
  nvgMultiply(dst.m[0].addr, src.m[0].unsafeAddr)

proc premultiply*(dst: var TransformMatrix, src: TransformMatrix) =
  nvgPremultiply(dst.m[0].addr, src.m[0].unsafeAddr)

proc inverse*(src: TransformMatrix): (bool, TransformMatrix) =
  var dst: TransformMatrix
  let res = nvgInverse(dst.m[0].addr, src.m[0].unsafeAddr)
  result = (res == 1, dst)

proc transformPoint*(xform: TransformMatrix,
                     x: float, y: float): (float, float) =
  var destX, destY: cfloat
  nvgTransformPoint(destX.addr, destY.addr, xform.m[0].unsafeAddr,
                    x.cfloat, y.cfloat)
  result = (destX.float, destY.float)

# }}}
#  {{{ Font functions

proc createFont*(ctx; name: string, filename: string): Font =
  result = wrapper.createFont(ctx, name, filename)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontAtIndex*(ctx; name: string, filename: string,
                        fontIndex: Natural): Font =
  result = createFontAtIndex(ctx, name, filename, fontIndex.cint)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontMem*(ctx; name: string,
                    data: var openArray[byte]): Font =
  result = createFontMem(ctx, name, cast[ptr byte](data[0].addr),
                         data.len.cint, freeData=0)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontMemAtIndex*(ctx; name: string, data: var openArray[byte],
                           fontIndex: Natural): Font =
  result = createFontMemAtIndex(ctx, name, cast[ptr byte](data[0].addr),
                                data.len.cint, freeData=0, fontIndex.cint)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")

#  }}}
# {{{ Text functions

proc textAlign*(ctx; halign: HorizontalAlign = haLeft,
                valign: VerticalAlign = vaBaseline) {.inline.} =
  textAlign(ctx, halign.cint or valign.cint)


template textMetrics*(ctx): tuple[ascender: float, descender: float,
                                  lineHeight: float] =

  var ascender, descender, lineHeight: cfloat
  textMetrics(ctx, ascender.addr, descender.addr, lineHeight.addr)
  (ascender.float, descender.float, lineHeight.float)


proc text*(ctx; x, y: float, s: string, `end`: string = ""): float {.inline.} =
  if s == "": return
  text(ctx, x.cfloat, y.cfloat, s, `end`)

# }}}
# {{{ Color functions

func clampToByte(i: int): byte = clamp(i, 0, 255).byte

func rgb*(r, g, b: int): Color =
  rgb(clampToByte(r), clampToByte(g), clampToByte(b))

func rgba*(r, g, b, a: int): Color =
  rgba(clampToByte(r), clampToByte(g), clampToByte(b), clampToByte(a))

func hsla*(h: float, s: float, l: float, a: float): Color =
  hsla(h.cfloat, s.cfloat, l.cfloat, clamp(a * 255, 0, 255).byte)

template withAlpha*(c: Color, a: int): Color =
  wrapper.withAlpha(c, clampToByte(a))

template withAlpha*(c: Color, a: float): Color =
  wrapper.withAlpha(c, a)

template gray*(g: float, a: float = 1.0): Color = rgba(g, g, g, a)
template gray*(g: int, a: int = 255): Color = rgba(g, g, g, a)

template black*(a: float = 1.0): Color = gray(0.0, a)
template white*(a: float = 1.0): Color = gray(1.0, a)

template black*(a: int): Color = black(a/255)
template white*(a: int): Color = white(a/255)

# Useful for debugging
template blue*(a: float = 1.0):    Color = rgba(0.0, 0.0, 1.0, a)
template green*(a: float = 1.0):   Color = rgba(0.0, 1.0, 0.0, a)
template cyan*(a: float = 1.0):    Color = rgba(0.0, 1.0, 1.0, a)
template red*(a: float = 1.0):     Color = rgba(1.0, 0.0, 0.0, a)
template magenta*(a: float = 1.0): Color = rgba(1.0, 0.0, 1.0, a)
template yellow*(a: float = 1.0):  Color = rgba(1.0, 1.0, 0.0, a)

template blue*(a: int):    Color = blue(a/255)
template green*(a: int):   Color = green(a/255)
template cyan*(a: int):    Color = cyan(a/255)
template red*(a: int):     Color = red(a/255)
template magenta*(a: int): Color = magenta(a/255)
template yellow*(a: int):  Color = yellow(a/255)

# {{{ toLinear*()
proc toLinear(c: Color): Color =
  # From: https://entropymine.com/imageworsener/srgbformula/
  proc conv(x: float): float=
    if x <= 0.0404482362771082: x / 12.92
    else: pow((x + 0.055) / 1.055, 2.4)

  rgb(conv(c.r), conv(c.g), conv(c.b))

# }}}
# {{{ fromLinear*()
proc fromLinear(c: Color): Color =
  # From: https://entropymine.com/imageworsener/srgbformula/
  proc conv(x: float): float=
    if x <=  0.00313066844250063: x * 12.92
    else: 1.055 * pow(x, 1/2.4) - 0.055

  rgb(conv(c.r), conv(c.g), conv(c.b))

# }}}
# {{{ toHSV*()
func toHSV*(c: Color): (float, float, float) =
  const HueMax = 360

  let
    r = c.r
    g = c.g
    b = c.b
    xmax = max(r, max(g, b))
    xmin = min(r, min(g, b))
    v = xmax
    c = xmax - xmin

  let h = if   c == 0: 0.0
          elif v == r: ((60 * (g-b)/c + HueMax) mod HueMax) / HueMax
          elif v == g: ((60 * (b-r)/c + 120)    mod HueMax) / HueMax
          else:        ((60 * (r-g)/c + 240)    mod HueMax) / HueMax  # v == b

  let s = if v == 0.0: 0.0 else: c/v

  (h.float, s.float, v.float)

# }}}
# {{{ hsva*()
func hsva*(h, s, v, a: float): Color =
  var r, g, b: float
  if s == 0.0:
    r = v
    g = v
    b = v
  else:
    let
      hf = if h >= 1.0: 0.0 else: h*6
      i = hf.int  # should be in the range 0..5
      f = hf - i.float  # fractional part

      m = v * (1 - s)
      n = v * (1 - s*f)
      k = v * (1 - s*(1-f))

    (r, g, b) = if   i == 0: (v, k, m)
                elif i == 1: (n, v, m)
                elif i == 2: (m, v, k)
                elif i == 3: (m, n, v)
                elif i == 4: (k, m, v)
                else:        (v, m, n)

  rgba(r, g, b, a)

# }}}

func luma*(c: Color): float =
  # Luma calculations according to the Rec. 709 spec
  # https://en.wikipedia.org/wiki/Luma_(video)
  c.r*0.2126 + c.g*0.7152 * c.b*0.0722

func isLight*(c: Color): bool = c.luma > 0.179
func isDark*(c: Color):  bool = not c.isLight

func weightedEuclidanDistance*(c: Color): float =
  sqrt(c.r*c.r*0.299 + c.g*c.g*0.587 + c.b*c.b*0.114)

func isLightEuclidan*(c: Color): bool =
  weightedEuclidanDistance(c) > 0.7

func isDarkEuclidan*(c: Color): bool = not c.isLightEuclidan

# }}}
# {{{ Image functions

proc createImage*(ctx; filename: string, flags: set[ImageFlags] = {}): Image =
  result = wrapper.createImage(ctx, filename, flags)
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc createImageMem*(ctx; flags: set[ImageFlags] = {},
                     data: var openArray[byte]): Image =
  result = createImageMem(ctx, flags, cast[ptr byte](data[0].addr),
                          data.len.cint)
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc createImageRGBA*(ctx; w: Natural, h: Natural, flags: set[ImageFlags] = {},
                      data: var openArray[byte]): Image =

  result = createImageRGBA(ctx, w.cint, h.cint, flags,
                           cast[ptr byte](data[0].addr))
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc imageSize*(ctx; image: Image): tuple[w, h: int] =
  var w, h: cint
  imageSize(ctx, image, w.addr, h.addr)
  result = (w.int, h.int)


# {{{ Image extensions

proc stbi_load(filename: cstring, x, y, channels: ptr cint,
               desiredChannels: cint): ptr UncheckedArray[byte]
    {.cdecl, importc: "stbi_load".}

proc stbi_image_free(data: ptr UncheckedArray[byte])
    {.cdecl, importc: "stbi_image_free".}


type ImageData* = object
  width*, height*: Natural
  numChannels*:    Natural
  data*:           ptr UncheckedArray[byte]

proc size*(d: ImageData): Natural =
  d.width * d.height * d.numChannels

proc `=destroy`*(d: ImageData) =
  if d.data != nil:
    stbi_image_free(d.data)


proc loadImage*(filename: string, desiredChannels: Natural = 4): ImageData =
  var w, h, channels: cint

  var data = stbi_load(filename, w.addr, h.addr, channels.addr,
                       desiredChannels.cint)

  if data == nil:
    raise newException(IOError, fmt"Could not load image '{filename}'")

  result = ImageData(
    width:  w.Natural,
    height: h.Natural,
    numChannels: desiredChannels,
    data: data
  )

# }}}
# }}}

# vim: et:ts=2:sw=2:fdm=marker
