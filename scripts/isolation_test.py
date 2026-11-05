#!/usr/bin/env python3
"""
The kit's central invariant, enforced.

Every component must be ONE file that compiles with nothing but
SwiftKitUI.swift beside it. That is the whole reason an agent can install a
component correctly: copy two files, done.

It is very easy to break by accident — a #Preview that reuses a sibling
component is enough, and the normal `swift build` will never notice because
everything is in one module. So we compile each component in its own throwaway
package.

Usage:
    python3 scripts/isolation_test.py            # all components
    python3 scripts/isolation_test.py SKCard     # just one
"""

from __future__ import annotations

import concurrent.futures
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
FOUNDATION = ROOT / "Sources/SwiftKitUI/SwiftKitUI.swift"
COMPONENTS = ROOT / "Sources/SwiftKitUI/Components"


def macro_plugin_path() -> str | None:
    """Where `#Preview` actually lives.

    `PreviewsMacros` ships in the MacOSX *platform*, not in the toolchain, and
    SwiftPM does not add that search path for a bare package built outside a
    workspace. Without it every component fails identically with "plugin for
    module 'PreviewsMacros' not found" — which reads exactly like a real
    isolation break and is not one. Finding that out the slow way once is
    enough; pass the path explicitly.
    """
    try:
        dev = subprocess.run(
            ["xcode-select", "-p"], capture_output=True, text=True, timeout=30
        ).stdout.strip()
    except Exception:
        return None
    candidate = pathlib.Path(dev) / "Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
    return str(candidate) if candidate.is_dir() else None


PLUGIN_PATH = macro_plugin_path()

MANIFEST = """// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Iso",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [.target(name: "Iso")]
)
"""


def check(component: pathlib.Path) -> tuple[str, bool, str]:
    tmp = pathlib.Path(tempfile.mkdtemp(prefix=f"iso-{component.stem}-"))
    try:
        src = tmp / "Sources/Iso"
        src.mkdir(parents=True)
        shutil.copy(FOUNDATION, src)
        shutil.copy(component, src)
        (tmp / "Package.swift").write_text(MANIFEST)

        # `xcrun` so we get the active Xcode toolchain rather than whatever a
        # bare `swift` happens to resolve to, and `--disable-sandbox` so the
        # macro plugin can be loaded from a temporary directory at all.
        cmd = ["xcrun", "swift", "build", "--disable-sandbox"]
        if PLUGIN_PATH:
            cmd += ["-Xswiftc", "-plugin-path", "-Xswiftc", PLUGIN_PATH]
        r = subprocess.run(cmd, cwd=tmp, capture_output=True, text=True, timeout=300)
        out = r.stdout + r.stderr
        if r.returncode == 0:
            return component.stem, True, ""

        # Surface only the first few real errors; the rest are cascades.
        errs = [l.strip() for l in out.splitlines() if ": error:" in l]
        return component.stem, False, "\n".join(f"      {e[:150]}" for e in errs[:4])
    except subprocess.TimeoutExpired:
        return component.stem, False, "      timed out"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    targets = sorted(COMPONENTS.glob("*.swift"))
    if len(sys.argv) > 1:
        wanted = set(sys.argv[1:])
        targets = [t for t in targets if t.stem in wanted]
        if not targets:
            print(f"no component matched {wanted}")
            return 1

    print(f"isolation test — {len(targets)} components, foundation only\n")
    failures = []
    # Each build is an independent process; run them wide.
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for name, ok, detail in pool.map(check, targets):
            print(f"  {'PASS' if ok else 'FAIL'}  {name}")
            if not ok:
                failures.append((name, detail))

    if failures:
        print(f"\n{len(failures)} component(s) do not compile alone:\n")
        for name, detail in failures:
            print(f"  {name}:\n{detail}\n")
        print("Usually a #Preview that reuses a sibling component. Inline it instead.")
        return 1

    print(f"\nall {len(targets)} components compile standalone")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
