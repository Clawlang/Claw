release: (build "ReleaseSafe")

build optimize="Debug":
  zig build -Doptimize={{optimize}}

test params='': build
  ./zig-out/bin/claw.exe {{params}}

update-std:
  git subtree pull --prefix="std/" std main --squash