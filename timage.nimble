# Package

version       = "0.1.0"
author        = "Thiago Navarro"
description   = "Text in images in Telegram, on the fly."
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["timage"]


# Dependencies

requires "nim >= 1.6.4"

requires "telebot"
requires "pixie"


from std/os import `/`

const
  dataDir = "data"
  robotoFont = "roboto-regular.ttf"

task setupFiles, "Setup":
  if not dirExists dataDir:
    mkDir dataDir
  if not fileExists dataDir / robotoFont:
    exec "wget https://github.com/treeform/pixie/raw/master/examples/data/Roboto-Regular_1.ttf -O " & dataDir / robotoFont
