type
  FontConfig* = tuple
    name, filename, url: string
    lineHeight: float

const
  dataDir* = "data"
  fonts*: seq[FontConfig] = @[
    (
      name: "Roboto Regular",
      filename: "roboto-regular.ttf",
      url: "https://github.com/treeform/pixie/raw/master/examples/data/Roboto-Regular_1.ttf",
      lineHeight: 18
    ),
    (
      name: "FiraCode Regular",
      filename: "firacode-regular.ttf",
      url: "https://cdnjs.cloudflare.com/ajax/libs/firacode/6.2.0/ttf/FiraCode-Medium.ttf",
      lineHeight: 20
    )
  ]
