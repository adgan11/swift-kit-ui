#!/usr/bin/env python3
"""Copy the generated registry into a website tree: `sync_site.py <site-root>`.

public/ui/ is what agents and the download link fetch. content/ui-registry/ is
what /swiftui/<slug> renders, statically imported because the Cloudflare Worker
has no filesystem at runtime. Run build_registry.py first.
"""
import json
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SITE = Path(sys.argv[1]).resolve()
SITE_URL = "https://theswiftk.it.com"

public = SITE / "public/ui"
content = SITE / "content/ui-registry"
shutil.rmtree(public, ignore_errors=True)
(public / "r").mkdir(parents=True)
content.mkdir(parents=True, exist_ok=True)

shutil.copy(ROOT / "registry/registry.json", public / "registry.json")
shutil.copy(ROOT / "LICENSE", public / "LICENSE.txt")
for f in (ROOT / "registry/r").glob("*.json"):
    shutil.copy(f, public / "r" / f.name)

llms = (ROOT / "registry/llms-components.md").read_text()
(public / "llms.txt").write_text(
    "# Swift Kit UI\n\n"
    "> Free, MIT-licensed SwiftUI components. Each is ONE Swift file that depends only on\n"
    "> SwiftKitUI.swift. Install foundation once, then add components. Never import one\n"
    "> component from another. No third-party packages. iOS 17+.\n\n"
    f"Registry: {SITE_URL}/ui/registry.json\n\n{llms}"
)

with zipfile.ZipFile(public / "swift-kit-ui.zip", "w", zipfile.ZIP_DEFLATED) as z:
    for name in ("Package.swift", "LICENSE", "README.md"):
        z.write(ROOT / name, f"swift-kit-ui/{name}")
    for f in sorted((ROOT / "Sources").rglob("*.swift")):
        z.write(f, f"swift-kit-ui/{f.relative_to(ROOT)}")

index = json.loads((ROOT / "registry/registry.json").read_text())
items = []
for entry in index["items"]:
    item = json.loads((ROOT / "registry/r" / f"{entry['name']}.json").read_text())
    f = item["files"][0]
    items.append({
        "name": item["name"],
        "title": item["title"],
        "description": item["description"].replace("*", "").replace("`", ""),
        "category": item["categories"][0],
        "slug": item["docs"].rsplit("/", 1)[-1],
        "usage": item.get("usage", ""),
        "variants": [v["title"] for v in item.get("variants", [])],
        "keywords": item.get("keywords", []),
        "fileName": Path(f["target"]).name,
        "lines": f["lines"],
        "source": f["content"],
    })
(content / "components.json").write_text(json.dumps(items, ensure_ascii=False))
(content / "links.json").write_text(
    json.dumps({i["name"]: i["slug"] for i in items}, indent=2) + "\n"
)
print(f"synced {len(items)} items to {SITE}")
