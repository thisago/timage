import std/asyncdispatch

when not defined release:
  import std/logging

from std/options import get, isSome
from std/strutils import strip, split
from std/strformat import fmt
from std/os import `/`, fileExists, existsOrCreateDir, execShellCmd, sleep
from std/random import randomize, rand
from std/times import now, format, DateTime, seconds, `<`, `+`
from std/json import `$`, parseJson, to
from std/tables import Table, `[]`, `[]=`, hasKey, del
import std/jsonutils

from pkg/checksums/md5 import `$`, toMD5
import pkg/telebot
import pkg/pixie

import timage/config

const
  apiSecretFile {.strdefine.} = "secret.key"
  chatCodeFile {.strdefine.} = "chat.code"
  framesDir = "frames"
  cacheJsonFile = "cached.json"

when fileExists chatCodeFile:
  const staticChatCode = strip readFile chatCodeFile
else:
  const staticChatCode = ""

let apiSecret = strip readFile apiSecretFile
var dbChatId = staticChatCode

randomize()

const fileName = "out.gif"

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

const frameTextMaxLen = 335
proc genImage(text, user: string) =
  ## returns true if was a gif
  const font = fonts[0]

  proc newFont(typeface: Typeface, size: float32, color: Color): Font =
    result = newFont typeface
    result.size = size
    result.paint.color = color
    # result.lineHeight = font.lineHeight

  let
    tf = readTypeface dataDir / font.filename

  var frameNum = 0
  proc genFrame(txt: string; first = false) =
    var text = txt
    if text.len > frameTextMaxLen:
      text = text[0..frameTextMaxLen]
    let image = newImage(200, 200)
    image.fill randomHsl()

    func smallerFont(min, added: float): float =
      let decreased = text.len / 5
      if decreased > added:
        return min
      result = (min + added) - decreased

    if first:
      image.fillText typeset(@[newSpan(user & "\l", tf.newFont(10, randomHsl(60))),], vec2(190, 190)), translate(vec2(5, 5))
    image.fillText typeset(@[newSpan(text & "\l", tf.newFont(smallerFont(12, 26), color(1, 1, 1))),], vec2(190, 190), vAlign = MiddleAlign, hAlign = CenterAlign)
    if first:
      image.fillText typeset(@[newSpan(nowFormatted(), tf.newFont(10, color rgba(255, 255, 255, 60))),], vec2(200, 190), vAlign = BottomAlign, hAlign = RightAlign), translate(vec2(0, 10))
    image.writeFile framesDir / fmt"{frameNum}.png"
    inc frameNum

  var i = 0
  for t in text.split "::":
    t.genFrame i == 0
    inc i

  discard execShellCmd fmt"convert -delay 500 -loop 0 {framesDir}/*.png {filename}; rm {framesDir}/*.png"


proc genAndUploadImg(b: Telebot; text, user: string; chatId = dbChatId): Future[string] {.async.} =
  ## Returns fileId
  text.genImage user

  let message = await b.sendAnimation(
    chatId = chatId,
    animation = "file://" & fileName,
    caption = if chatId == dbChatId: fmt"{user} at {nowFormatted()}" else: "",
  )

  result = message.document.get.fileId

var cache: Table[string, string] # md5 hash, fileid
proc saveCache =
  cacheJsonFile.writeFile $cache.toJson
proc importCache =
  try:
    cache = cacheJsonFile.readFile.parseJson.to type cache
  except IOError:
    discard

var lastSentMsg = now()
proc waitNextSec =
  while lastSentMsg + 1.seconds > now(): # rate limit
    sleep 500
  lastSentMsg = now()

proc hash(user, text: string): string =
  $toMD5 user & text

proc inlineHandler(b: Telebot; q: InlineQuery): Future[bool] {.async, gcsafe.} =
  if q.fromUser.isBot: return
  if q.query.len == 0 or q.query[^1] != '.': return
  let
    text = q.query[0..^2]
    user = $q.fromUser
    hash = user.hash text
  debug fmt"Generating '{text}' for '{user}'"
  {.gcsafe.}:
    try:
      var gifFileId: string
      if cache.hasKey(hash):
        if cache[hash].len > 0:
          debug fmt"Using cached already generated '{text}' for '{user}'"
          gifFileId = cache[hash]
        else:
          return
      else:
        cache[hash] = ""
        waitNextSec()
        gifFileId = await b.genAndUploadImg(text, user)
        cache[hash] = gifFileId

      waitNextSec()

      discard waitFor b.answerInlineQuery(
        q.id,
        @[
          InlineQueryResultCachedGif(
            kind: "gif",
            gifFileId: gifFileId,
            id: "0"
          )
        ]
      )
      saveCache()
      result = true
    except:
      error fmt"Error when generating '{text}' for '{user}': " & getCurrentExceptionMsg()
      cache.del hash

proc updateHandler(b: Telebot, q: Update): Future[bool] {.gcsafe, async.} =
  if q.message.isSome:
    var resp = q.message.get
    if resp.fromUser.isSome and resp.fromUser.get.isBot: return
    if resp.text.isSome:
      var text = resp.text.get
      if resp.text.get.len == 0 or resp.text.get[^1] != '.': return

      text = text[0..^2]
      let user = $resp.fromUser.get

      {.gcsafe.}: discard await b.genAndUploadImg(text, user, $resp.chat.id)

      result = true

proc main(chatId = "") =
  when not defined release:
    addHandler newConsoleLogger(fmtStr = "$levelname, [$time] ")
  addHandler newFileLogger("error.log", levelThreshold = lvlError)

  discard existsOrCreateDir framesDir

  if dbChatId.len == 0 and chatId.len == 0:
    quit fmt"Create '{chatCodeFile}' file or provide it in CLI"
  if chatId.len > 0:
    dbChatId = chatId

  importCache()

  var bot: TeleBot
  while true:
    try:
      if not bot.isNil:
        discard waitFor close bot
      let bot = newTeleBot apiSecret
      bot.onInlineQuery inlineHandler
      bot.onUpdate updateHandler
      bot.poll(timeout = 1000)
    except:
      echo "crash: " & getCurrentExceptionMsg()
      sleep 2000

when isMainModule:
  import pkg/cligen

  dispatch main
