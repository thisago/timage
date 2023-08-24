import std/asyncdispatch

when not defined release:
  import std/logging

from std/options import get, some
from std/strutils import strip, join, toLowerAscii, contains, split,
                          multiReplace, parseInt

import pkg/telebot
import pkg/pixie

const apiSecretFile {.strdefine.} = "secret.key"
let apiSecret = strip readFile apiSecretFile

proc inlineHandler(b: Telebot, u: InlineQuery): Future[bool] {.async, gcsafe.} =
  if u.fromUser.isBot: return

  discard waitFor b.answerInlineQuery(
    u.id,
    @[
      InlineQueryResultPhoto(
        photoUrl: "",
        # thumbnailUrl: "",
        # photoWidth: "",
        # photoHeight: "",
        # title: "",
        # description: "",
        # caption: ""
      )
    ]
  )

proc main(mybibleModule, ozzuuBibleTranslation: string; dbUser = "", dbPass = "") =
  when not defined release:
    var L = newConsoleLogger(fmtStr = "$levelname, [$time] ")
    addHandler(L)

  let bot = newTeleBot apiSecret
  bot.onInlineQuery inlineHandler
  bot.poll(timeout = 300)

when isMainModule:
  import pkg/cligen

  dispatch main
