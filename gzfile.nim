

when defined(macosx):
  const
    Lib = "libz(|.0).dylib"
elif defined(linux):
  const
    Lib = "libz.so"

{.pragma: mylib, dynlib: Lib.}


type gzFile {.pure,final.} = ptr object

proc gzread(g:gzFile, buf:pointer, len:cuint): cint {.cdecl, importc:"gzread", mylib.}
proc gzgets(g:gzFile, buf:pointer, len:cuint): cstring {.cdecl, discardable, importc:"gzgets", mylib.}
proc gzwrite(g:gzFile, buf:pointer, len:cuint): cint {.cdecl, importc:"gzwrite", mylib.}
proc gzflush(g:gzFile): cint {.cdecl, importc:"gzflush", mylib.}
proc gzeof(g:gzFile): cint {.cdecl, importc:"gzeof", mylib.}
proc gzerror(g:gzFile, errnum:ptr cint): cstring {.cdecl, importc:"gzerror", mylib.}
proc gzclearerr(g:gzFile) {.cdecl, importc:"gzclearerr", mylib.}
proc gzbuffer(g:gzFile, size:cuint) {.cdecl, importc:"gzbuffer", mylib.}
proc gzputc(g:gzFile, c:cint): cint {.cdecl, importc:"gzputc", mylib.}

proc gzdopen(fd:cint, mode:cstring): gzFile {.cdecl, importc:"gdzopen", myLib.}
proc gzopen(fname:cstring, mode:cstring): gzFile {.cdecl, importc:"gzopen", myLib.}

proc gzclose(g:gzFile): cint {.cdecl, importc:"gzclose", discardable, myLib.}
proc gztell(g:gzFile): clong {.cdecl, importc:"gztell", myLib.}


type GZFile* = object
  c: gzFile

const DEFAULT_BUF_SIZE = 8192

proc open*(g:var GZFile, path:string, mode:string="r", bufsize:int=DEFAULT_BUF_SIZE): bool =
  g.c = gzopen(path, mode)
  if g.c == nil: return false
  if bufsize != DEFAULT_BUF_SIZE:
    g.c.gzbuffer(bufsize.cuint)
  return true

template tell*(g:GZFile): int64 = g.c.gztell
proc close*(g:GZFile): int {.discardable.} = g.c.gzclose.int

proc readBuffer*(g:GZFile, buffer:pointer, len:Natural): int =
  # reads len bytes into the buffer pointed to by buffer. Returns the actual number of bytes that have been read which may be less than len (if not as many bytes are remaining), but not greater.
  g.c.gzread(buffer, len.cuint).int

proc error*(g:GZFile): string =
  ## return the last error, if any associated with this file
  var err: cint
  result = $gzerror(g.c, err.addr)

proc write*(g:GZFile, lines: varargs[string]): bool {.inline, discardable.} =
  for line in lines:
    result = 0 != g.c.gzwrite(line[0].unsafeAddr.pointer, line.len.cuint)
    if not result:
      var err:cint
      let msg = gzerror(g.c, err.addr)
      if err != 0:
        raise newException(IOError, $msg)
      break


proc write_line*(g:GZFile, lines: varargs[string]): bool {.inline, discardable.} =
  g.write(lines)
  result = 0 != g.c.gzputc('\n'.cint)

proc readLine(g:GZFile, line: var string): bool =
  ## Newline character(s) are not part of the returned string. Returns false if the end of the file has been reached, true otherwise. If false is returned line contains no new data
  if line.len < 64: line.setLen(64)
  var off = 0
  # if the last value in the buffer is not \0, then we
  # have read a full line without filling it.
  line[line.high] = 1.char

  while true:
    let cs = g.c.gzgets(line[off].addr.pointer, (line.len - off).cuint)
    if cs == nil:
      if gzeof(g.c) == 1.cint: return false
      raise newException(IoError, "erorr in readline")
    if line[off] == 0.char:
      line.setLen(0)
      return true
    # read all without getting to end of buffer
    if line[line.high] != 0.char:
      line.setLen(off + cs.len)
      return true

    off = line.len
    line.setLen(line.len * 2)
    line[line.high] = 1.char
  result = true

iterator gzLines*(path: string): string =
  var line = newString(128)
  var g: GZFile
  if not open(g, path):
    raise newException(OSError, "unable to open file:" & path)
  while g.readLine(line):
    yield line
  g.close

iterator lines*(g: GZFile): string =
  var line = newString(128)
  while g.readLine(line):
    yield line

when isMainModule:
  import os
  var f = paramStr(1)
  echo f

  var gz: GZFile
  if not gz.open(f):
    quit "couldn't open file"
  echo gz.tell
  var line:string
  while gz.readLine(line):
    echo ">>>", line

  echo "error:", gz.error
  echo gz.tell
  gz.close


  if not gz.open("xxx.gz", "w7"):
    quit "couldn't open file for writing"
  for i in 0..10:
    gz.write("hello\n")
    gz.write("world\n")
  for i in 0..10:
    gz.write_line "hello", "cruel", "world"

  gz.close
