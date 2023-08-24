import std/asyncdispatch

when not defined release:
  import std/logging

from std/options import get, isSome
from std/strutils import strip
from std/strformat import fmt
from std/os import `/`, fileExists
from std/random import randomize, rand
from std/times import now, format

import pkg/telebot
import pkg/pixie

import timage/config

const apiSecretFile {.strdefine.} = "secret.key"
const chatCodeFile {.strdefine.} = "chat.code"

when fileExists chatCodeFile:
  const staticChatCode = strip readFile chatCodeFile
else:
  const staticChatCode = ""

let apiSecret = strip readFile apiSecretFile
var dbChatId = staticChatCode

randomize()

const fileName = "text.png"

proc nowFormatted: string =
  now().format "yyyy/MM/dd hh:mm:ss tt"

proc `$`(u: User): string =
  result = u.firstName
  if u.lastName.isSome:
    result.add " " & u.lastName.get
  if u.username.isSome:
    result.add " (@" & u.username.get & ")"

proc randomHsl(lightness = 10'f32): Color =
  color hsl(float rand(0..255), float rand(0..255), lightness)

proc genImage(text, user: string) =
  let image = newImage(200, 200)
  image.fill randomHsl()

  const font = fonts[0]

  proc newFont(typeface: Typeface, size: float32, color: Color): Font =
    result = newFont(typeface)
    result.size = size
    result.paint.color = color
    result.lineHeight = font.lineHeight

  let tf = readTypeface dataDir / font.filename

  image.fillText typeset(@[newSpan(user & "\l", tf.newFont(14, randomHsl(50))),], vec2(190, 190)), translate(vec2(5, 5))
  image.fillText typeset(@[newSpan(text & "\l", tf.newFont(12, color(1, 1, 1))),], vec2(190, 190), vAlign = MiddleAlign, hAlign = CenterAlign), translate(vec2(5, 5))
  image.fillText typeset(@[newSpan(nowFormatted(), tf.newFont(13, color rgba(255, 255, 255, 60))),], vec2(190, 190), vAlign = BottomAlign), translate(vec2(5, 5))
  image.writeFile fileName

proc inlineHandler(b: Telebot, u: InlineQuery): Future[bool] {.async, gcsafe.} =
  if u.fromUser.isBot: return
  if u.query.len == 0 or u.query[^1] != '.': return

  let
    text = u.query[0..^2]
    user = $u.fromUser

  text.genImage user

  {.gcsafe.}:
    let message = await b.sendPhoto(
      chatId = dbChatId,
      photo = "file://" & fileName,
      caption = fmt"{user} at {nowFormatted()}"
    )

  discard waitFor b.answerInlineQuery(
    u.id,
    @[
      InlineQueryResultCachedPhoto(
        kind: "photo",
        photoFileId: message.photo.get[0].fileId,
        id: "0"
      )
    ]
  )

proc main(chatId = "") =
  when not defined release:
    var L = newConsoleLogger(fmtStr = "$levelname, [$time] ")
    addHandler(L)

  if dbChatId.len == 0 and chatId.len == 0:
    quit fmt"Create '{chatCodeFile}' file or provide it in CLI"
  if chatId.len > 0:
    dbChatId = chatId

  let bot = newTeleBot apiSecret
  bot.onInlineQuery inlineHandler
  bot.poll(timeout = 300)

when isMainModule:
  import pkg/cligen

  dispatch main
