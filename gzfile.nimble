# Package

version       = "0.0.1"
author        = "Brent Pedersen"
description   = "read and write gzipped files with your systems zlib"
license       = "MIT"

# Dependencies
requires "nim >= 0.19.2" #, "nim-lang/c2nim>=0.9.13"


task test, "run the tests":
  exec "nim c -d:debug --lineDir:on -r gzfile.nim gzfile.nimble"

task docs, "make docs":
  exec "nim doc2 gzfile.nim; mkdir -p docs; mv gzfile.html docs/index.html"
