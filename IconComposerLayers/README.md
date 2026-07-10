# Bread & Butter — Icon Composer layers

Flat source layers for building the Liquid Glass app icon in Apple's Icon
Composer. No lighting, gloss, or shadows are baked in — Icon Composer adds the
glass material, specular, and blur itself.

- `svg/` — vector layers (preferred; scale cleanly at any size)
- `png/` — 1024×1024 fallbacks (background opaque; marks + knife transparent)

Canvas is 1024×1024, full-bleed. watchOS masks the icon to a circle, so all the
important detail sits near the center.

## Stacking order (bottom → top)

1. **1-background** — the butter (`#F3CE60`) / baguette (`#E8983A`) split. Base
   fill; leave as a plain background layer, no glass.
2. **2-marks** — butter segment ticks (`#D2A62C`) and baguette crust scores
   (`#BE6E1A`). Optional texture; a light material reads nicely.
3. **3-knife** — the white slider/knife down the seam. This is the hero glass
   element: give it a translucent/glass material with a specular highlight.

## Tips

- Set the document to the watchOS (round) icon shape to preview the mask.
- Keep the knife on top so its glass highlight catches the light.
- The baked PNG already in the app (`…/AppIcon.appiconset/icon-1024.png`) is a
  static stand-in; replace the app icon with the exported `.icon` when ready.
