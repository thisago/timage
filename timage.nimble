# Package

version       = "0.1.0"
author        = "Thiago Navarro"
description   = "Telegram inline text images generation, on the fly"
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["timage"]

binDir = "build"

# Dependencies

requires "nim >= 1.6.4"

requires "telebot"
requires "pixie"
requires "dataUrl"


from std/os import `/`

import src/timage/config

task setupFiles, "Setup":
  if not dirExists dataDir:
    mkDir dataDir
  for font in fonts:
    if not fileExists dataDir / font.filename:
      exec "wget " & font.url & " -O " & dataDir / font.filename

task buildRelease, "release":
  exec "nimble -d:danger --opt:speed build"
