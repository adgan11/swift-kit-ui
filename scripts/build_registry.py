#!/usr/bin/env python3
"""
Builds the Swift Kit UI registry from `registry/components.json` + the real
.swift files.

Why a generator rather than hand-written JSON: the registry embeds component
source. Hand-maintained, it drifts from the actual files within a week and an
agent installs code that no longer matches the docs. Generated, it cannot.

Emits:
  registry/registry.json      index — what an agent or the MCP server fetches first
  registry/r/<name>.json      one item per component, with source inlined
  registry/llms-components.md markdown index for llms.txt

Paid components have their `source` withheld from the public payload. The
preview and metadata stay public (that is the SEO surface); the code ships only
through a licence-checked path.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REGISTRY_DIR = ROOT / "registry"
SRC = REGISTRY_DIR / "components.json"
SITE = "https://theswiftk.it.com"
SCHEMA = f"{SITE}/ui/schema/registry-item.json"


def load() -> dict:
    if not SRC.exists():
        sys.exit(f"missing {SRC}")
    return json.loads(SRC.read_text())


def read_source(rel_path: str) -> str:
    f = ROOT / rel_path
    if not f.exists():
        sys.exit(f"registry references a file that does not exist: {rel_path}")
    return f.read_text()


def build() -> int:
    data = load()
    items = data["items"]
    out_dir = REGISTRY_DIR / "r"
    out_dir.mkdir(parents=True, exist_ok=True)

    index_items = []
    md_lines = ["## Swift Kit UI components", ""]

    for item in items:
        name = item["name"]
        is_free = item.get("tier", "pro") == "free"

        files = []
        for spec in item["files"]:
            entry = {
                "path": spec["path"],
                "target": spec["target"],
                "type": item["type"],
            }
            source = read_source(spec["path"])
            entry["lines"] = source.count("\n") + 1
            if is_free:
                entry["content"] = source
            else:
                # Deliberate: paid source never enters the public registry.
                entry["content"] = None
                entry["requiresLicense"] = True
            files.append(entry)

        payload = {
            "$schema": SCHEMA,
            "name": name,
            "type": item["type"],
            "title": item["title"],
            "description": item["description"],
            "author": data["author"],
            "tier": item.get("tier", "pro"),
            "platforms": data["platforms"],
            "categories": item.get("categories", []),
            # Always empty by design — the kit has zero third-party packages, so
            # an agent never has to resolve SPM dependencies to use a component.
            "dependencies": [],
            "registryDependencies": item.get("registryDependencies", []),
            "files": files,
            "variants": item.get("variants", []),
            "usage": item.get("usage", ""),
            "docs": item.get("docs", ""),
            "keywords": item.get("keywords", []),
        }
        if "meta" in item:
            payload["meta"] = item["meta"]

        (out_dir / f"{name}.json").write_text(json.dumps(payload, indent=2) + "\n")

        index_items.append({
            "name": name,
            "type": item["type"],
            "title": item["title"],
            "description": item["description"],
            "tier": item.get("tier", "pro"),
            "categories": item.get("categories", []),
            "registryDependencies": item.get("registryDependencies", []),
            "variants": [v["id"] for v in item.get("variants", [])],
            "docs": item.get("docs", ""),
            "url": f"{SITE}/ui/r/{name}.json",
        })

        lock = "" if is_free else " _(Pro)_"
        md_lines.append(f"- [{item['title']}]({item.get('docs','')}){lock} — {item['description']}")
        md_lines.append(f"  - registry: {SITE}/ui/r/{name}.json")

    index = {
        "$schema": f"{SITE}/ui/schema/registry.json",
        "name": data["name"],
        "homepage": data["homepage"],
        "author": data["author"],
        "license": data["license"],
        "platforms": data["platforms"],
        "install": {
            "manual": "Add SwiftKitUI.swift once, then drop in any component file beside it.",
            "download": f"{SITE}/ui/swift-kit-ui.zip",
            "llms": f"{SITE}/ui/llms.txt",
        },
        "rules": (
            "Every component is ONE self-contained Swift file that depends only on "
            "`foundation` (SwiftKitUI.swift). Never import one component from another. "
            "There are no third-party package dependencies."
        ),
        "count": len(index_items),
        "items": index_items,
    }
    (REGISTRY_DIR / "registry.json").write_text(json.dumps(index, indent=2) + "\n")
    (REGISTRY_DIR / "llms-components.md").write_text("\n".join(md_lines) + "\n")

    # Mirror into the gallery app's bundle. The app shows the SAME generated
    # JSON the website and MCP server serve, so the code a customer copies out
    # of the gallery is byte-identical to what they would install.
    gallery = ROOT / "Gallery" / "Resources" / "registry"
    if (ROOT / "Gallery").exists():
        gallery.mkdir(parents=True, exist_ok=True)
        for stale in gallery.glob("*.json"):
            stale.unlink()
        for item in items:
            name = item["name"]
            (gallery / f"{name}.json").write_text((out_dir / f"{name}.json").read_text())
        # The index too: the gallery builds its component list from this, so the
        # app can never show a catalogue that disagrees with the registry.
        (gallery / "registry.json").write_text((REGISTRY_DIR / "registry.json").read_text())
        print(f"mirrored {len(items)} items + index -> Gallery/Resources/registry/")

    free = sum(1 for i in index_items if i["tier"] == "free")
    print(f"registry: {len(index_items)} items ({free} free, {len(index_items)-free} pro)")
    for i in index_items:
        print(f"  {i['tier']:5}  {i['name']:14} -> {i['url']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(build())
