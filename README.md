this is a simple wrapper around your systems zlib.
it has an interface like nim's `File`.

```Nim
var gz: GZFile
if not gz.open(f, bufsize=16384):
  quit "couldn't open file"
echo gz.tell
var line:string
while gz.readLine(line):
  echo line

echo gz.error
echo gz.tell
gz.close

```

and writing:

```Nim
var wgz: GZFile
if not wgz.open(f, "w6"):
  quit "couldn't open file"

for i in 0..10:
  wgz.write("hello ", "big ")
  wgz.write_line("world")
wgz.close
```

this works for both gzipped and regular files
