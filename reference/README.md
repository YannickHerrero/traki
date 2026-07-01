# Reference — original design export

These files are the original `traki.zip` design-tool export that this app is built from. They are **not compiled**; they are the source of truth for behaviour, layout, colors, and copy.

| File | What it is |
|---|---|
| `Traki - Product Spec.dc.html` | The product specification (principles, modes, screens, logging, widgets, appearance, navigation, roadmap). |
| `Traki.dc.html` | The fully-wired interactive prototype. Its `<script>` logic block is the authoritative source for the **data model, color palettes (`palette()`), mode definitions (`cats`), formatters (`fmtDur`/`fmtClock`), and every interaction**. |
| `Home Styles.dc.html` | The five explored home-screen directions. Direction **1D "Playful Cards"** is the one implemented in the prototype and in this app. |
| `doc-page.js`, `support.js`, `frames/ios-frame.jsx` | The design tool's runtime + an iOS 26 (Liquid Glass) device frame. Needed only to render the `.dc.html` files in a browser. |

To view a prototype: open the `.dc.html` file in a browser (it loads `support.js` alongside).
