# Swift Kit UI Gallery

The exact preview. Real SwiftUI on a real device — not an HTML recreation.

## Run it

```bash
cd Gallery
xcodegen generate          # regenerate the project after editing project.yml
open SwiftKitUIGallery.xcodeproj
```

Pick any simulator and hit run. `project.yml` is the source of truth; the
`.xcodeproj` is generated and should not be hand-edited.

## Capture harness

Every screen is reachable from the command line, which is how the marketing
site's component recordings get produced — deterministically, same framing
every time:

```bash
xcrun simctl launch <device> com.theswiftkit.ui.gallery \
  --component sk-toggle --variant liquid-glass --scheme dark
```

`--component` takes a registry id, `--variant` a variant id, `--scheme`
light|dark. Omit them all for the normal browsing experience.

## Why it consumes the package

The gallery depends on SwiftKitUI as a Swift package, exactly the way a customer
does — never by reaching into the source folder. If the public API is awkward,
building this app is where it shows up first.

## Source panel

The code shown in the app is loaded from `Resources/registry/*.json`, mirrored
there by `scripts/build_registry.py`. It is the same generated payload the
website and the MCP server serve, so what you copy here is byte-identical to
what you would install. Re-run the script after changing any component.
