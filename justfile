release target='native' : (build target "ReleaseSafe")
  @[ -d bin/ ] || mkdir bin/
  @cp zig-out/bin/claw.exe bin/
  @cp -r std/ bin/
  @cp LICENSE bin/

build target='native' optimize="Debug":
  zig build -Dtarget={{target}} -Doptimize={{optimize}}

test *args='': build
  ./zig-out/bin/claw.exe {{args}}

update-std:
  git subtree pull --prefix="std/" std main --squash