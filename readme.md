<div align=center>

# Timage

#### Multi-frame text image generation in Telegram

**[About](#about) - [Usage](#usage)** - [License](#license)

</div>

## About

The [@timagebot](https://timagebot.t.me) is a Telegram bot that generates a
multi-frame GIF with the provided text!

A custom syntax will be implemented later to allow to config color, font and
text position.

This bot uploads the image in a custom group/channel and reuses the cached photo!

Also, all generated and uploaded GIFs are cached, but you can only access the
cached content if the same bot uploaded. Same cache for multiple instances is
not possible.

## Usage

> **Note**
> The ending dot (`.`) in text content, it will be removed from image, but
> it shows to bot that the message is finished. If you want to place a ending dot,
> just put two dots in end.

### Inline mode

Call the bot in any chat:

```text
@timagebot Hello World!.
```

Multi frame

```text
@timagebot Hello World::Bye World!.
```

Note that inline query can be just 256 characters limit, for larger text, send
it to the bot privately.

### Chatting with bot

Just send the message to [@timagebot](https://timagebot.t.me).

Example

```
Lorem ipsum dolor sit amet consectetur adipisicing elit. Mollitia rem autem hic, vero ipsum maxime placeat similique facere molestias recusandae enim accusantium iure fuga harum ea ullam quod laboriosam excepturi.
```


## TODO

- [ ] More styling options

## License

This Telegram bot is FOSS, licensed over GPL-3 license.
