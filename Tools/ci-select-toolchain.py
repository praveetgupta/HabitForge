#!/usr/bin/env python3
"""Finds an Xcode that can actually build this project for an iOS Simulator.

Two things go wrong on GitHub's macOS runners, and neither is visible from the obvious
checks:

  * The newest installed Xcode may be too new for the runner's macOS (e.g. Xcode 26.3 on
    macOS 15.7). It still launches, and `xcrun simctl list runtimes` still reports iOS
    runtimes, but `xcodebuild` enumerates no iOS Simulator destinations at all.
  * `simctl` is shared across Xcodes, so a device name taken from it can belong to a
    runtime the selected Xcode cannot target.

So rather than inferring, this asks each installed Xcode what it can actually build for
(`xcodebuild -showdestinations`) and picks the newest one that offers a concrete iPhone
simulator. Prints two shell-ready lines:

    DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer
    DESTINATION=platform=iOS Simulator,OS=18.6,name=iPhone 16 Pro
"""

import glob
import os
import re
import subprocess
import sys

# Destination lines look like:
#   { platform:iOS Simulator, arch:arm64, id:..., OS:26.5, name:iPhone 17 Pro }
# The field list varies (arch is not always present), so parse the braces rather than
# matching a fixed field order. The bare "Any iOS Simulator Device" placeholder has no OS
# and cannot be tested on, so requiring OS is what filters it out.
BRACES = re.compile(r"\{([^}]*)\}")


def version_key(path: str) -> tuple:
    return tuple(int(p) for p in re.findall(r"\d+", os.path.basename(path))) or (0,)


def destinations(developer_dir: str) -> list:
    env = dict(os.environ, DEVELOPER_DIR=developer_dir)
    try:
        result = subprocess.run(
            ["xcodebuild", "-project", "HabitForge.xcodeproj",
             "-scheme", "HabitForge", "-showdestinations"],
            capture_output=True, text=True, env=env, timeout=600,
        )
    except subprocess.TimeoutExpired:
        return []

    found = []
    for block in BRACES.findall(result.stdout):
        fields = {}
        for part in block.split(", "):
            key, sep, value = part.partition(":")
            if sep:
                fields[key.strip()] = value.strip()

        if fields.get("platform") != "iOS Simulator":
            continue
        name, os_version = fields.get("name", ""), fields.get("OS")
        if not os_version or not name.startswith("iPhone"):
            continue
        found.append((tuple(int(p) for p in os_version.split(".")), os_version, name))
    return found


def main() -> int:
    candidates = sorted(glob.glob("/Applications/Xcode*.app"), key=version_key, reverse=True)
    if not candidates:
        print("No Xcode found in /Applications", file=sys.stderr)
        return 1

    for app in candidates:
        developer_dir = os.path.join(app, "Contents", "Developer")
        if not os.path.isdir(os.path.join(developer_dir, "Platforms", "iPhoneSimulator.platform")):
            print(f"skip {app}: no iPhoneSimulator platform", file=sys.stderr)
            continue

        found = destinations(developer_dir)
        if not found:
            print(f"skip {app}: reports no concrete iOS Simulator destinations", file=sys.stderr)
            continue

        found.sort()
        _, os_version, name = found[-1]
        print(f"using {app} -> iPhone simulator '{name}' on iOS {os_version}", file=sys.stderr)
        print(f"DEVELOPER_DIR={developer_dir}")
        print(f"DESTINATION=platform=iOS Simulator,OS={os_version},name={name}")
        return 0

    print("No installed Xcode offers a concrete iOS Simulator destination", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
