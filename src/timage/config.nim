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
  ]
