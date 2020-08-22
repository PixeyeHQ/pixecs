# Package
version       = "2020.08.01"
author        = "Dmitry 'Pixeye' Mitrofanov"
description   = "A pragmatic entity-component-system module"
license       = "MIT"
srcDir        = "src"


# Dependencies
requires "nim >= 1.2.6"

task bench, "Benchmark":
   exec "nim c -d:danger --passC:-flto --passL:-s --gc:boehm --out:examples/benchmark tests/pixecs_bench.nim"

task test, "run tests":
  exec "nim c -p:. -r tests/pixecs_tests.nim"
