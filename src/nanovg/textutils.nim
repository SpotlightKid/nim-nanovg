## NanoVG text helper functions using unsecure char pointer arithmetic
##
## You may want to compile programs using this module with:
##
##     --warning:CStringConv:off
##     --warning:PtrToCstringConv:off

import wrapper

using ctx: NVGContext

type
  TextRow* = object
    startPos*: Natural
    endPos*:   Natural
    nextPos*:  Natural
    width*:    float
    minX*:     float
    maxX*:     float

template `++`[A](a: ptr A, offset: int): ptr A =
  cast[ptr A](cast[int](a) + offset)


template `--`[A](a, b: ptr A): int =
  cast[int](a) - cast[int](b)


template getStartPtr(s: string, startPos: Natural): cstring =
  s[0].unsafeAddr ++ startPos


template getEndPtr(s: string, endPos: int): cstring =
  if endPos < 0: nil else: s[0].unsafeAddr ++ endPos ++ 1


proc text*(ctx; x, y: float, s: string, startPos: Natural,
           endPos: int = -1,): float {.inline.} =
  if s == "": return
  text(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos))


proc textBox*(ctx; x, y, breakRowWidth: float, s: string,
              startPos: Natural = 0, endPos: int = -1,) {.inline.} =
  if s == "": return
  textBox(ctx, x, y, breakRowWidth,
          getStartPtr(s, startPos), getEndPtr(s, endPos))


proc textBreakLines*(ctx; s: string, startPos: Natural = 0, endPos: int = -1,
                     breakRowWidth: float, maxRows: int = -1): seq[TextRow] =
  result = newSeq[TextRow]()

  if s == "" or maxRows == 0: return

  var
    rows: array[64, wrapper.TextRow]
    rowsLeft = if maxRows >= 0: maxRows else: rows.len
    startPtr = getStartPtr(s, startPos)
    endPtr   = getEndPtr(s, endPos)

  while rowsLeft > 0:
    let numRows = wrapper.textBreakLines(ctx, startPtr, endPtr,
                                         breakRowWidth.cfloat, rows[0].addr,
                                         min(rowsLeft, rows.len).cint)
    for i in 0..<numRows:
      let row = rows[i]
      let sPtr = s[0].unsafeAddr

      let tr = TextRow(
        startPos: row.startPtr[0].unsafeAddr -- sPtr,
        # endPtr points to the char after the last character in the line
        endPos:   row.endPtr[0].unsafeAddr -- sPtr - 1,
        nextPos:  row.nextPtr[0].unsafeAddr -- sPtr,
        width:    row.width,
        minX:     row.minX,
        maxX:     row.maxX
      )
      result.add(tr)

    if numRows == 0:
      rowsLeft = 0
    else:
      startPtr = rows[numRows-1].nextPtr
      rowsLeft -= numRows


template textBreakLines*(ctx; s: string, startPos: Natural = 0,
                         breakRowWidth: float,
                         maxRows: int = -1): seq[TextRow] =
  textBreakLines(ctx, s, startPos, endPos = -1, breakRowWidth, maxRows)


template textBreakLines*(ctx; s: string, breakRowWidth: float,
                         maxRows: int = -1): seq[TextRow] =
  textBreakLines(ctx, s, startPos=0, endPos = -1, breakRowWidth, maxRows)


proc horizontalAdvance*(ctx; x: float, y: float, s: string,
                        startPos: Natural = 0,
                        endPos: int = -1): float {.inline.} =
  if s == "": return
  textBounds(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos),
             bounds=nil)


proc textWidth*(ctx; s: string, startPos: Natural = 0,
                    endPos: int = -1): float {.inline.} =
  if s == "": return
  textBounds(ctx, 0, 0, getStartPtr(s, startPos), getEndPtr(s, endPos),
             bounds=nil)


proc textBounds*(ctx; x: float, y: float, s: string, startPos: Natural = 0,
                 endPos: int = -1): tuple[bounds: Bounds,
                                          horizAdvance: float] {.inline.} =
  if s == "": return

  var b: Bounds
  let adv = textBounds(ctx, x, y,
                       getStartPtr(s, startPos), getEndPtr(s, endPos),
                       bounds=b.x1.addr)
  result = (b, adv.float)


proc textBoxBounds*(ctx; x: float, y: float,
                    breakRowWidth: float, s: string,
                    startPos: Natural = 0, endPos: int = -1): Bounds {.inline.} =
  if s == "": return
  textBoxBounds(ctx, x, y, breakRowWidth,
                getStartPtr(s, startPos), getEndPtr(s, endPos), result.x1.addr)


proc textGlyphPositions*(ctx; x: float, y: float,
                         s: string, startPos: Natural = 0, endPos: int = -1,
                         positions: var openArray[GlyphPosition]): int {.inline.} =
  if s == "": return
  textGlyphPositions(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos),
                     positions[0].addr, positions.len.cint)


template textGlyphPositions*(ctx; x: float, y: float,
                             s: string, startPos: Natural = 0,
                             positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, s, startPos, endPos = -1, positions)


template textGlyphPositions*(ctx; x: float, y: float, s: string,
                             positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, s, startPos=0, endPos = -1, positions)
