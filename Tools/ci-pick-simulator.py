#!/usr/bin/env python3
"""Prints the name of an available iPhone simulator on the newest installed iOS runtime.

GitHub's macOS runner images change their simulator line-up between releases, so CI resolves
a concrete device name at run time instead of pinning one that may disappear.
"""

import json
import re
import subprocess
import sys


def main() -> int:
    raw = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout

    candidates = []
    for runtime, devices in json.loads(raw)["devices"].items():
        if "iOS" not in runtime:
            continue
        version = tuple(int(part) for part in re.findall(r"\d+", runtime.split(".iOS-")[-1]))
        for device in devices:
            if device.get("isAvailable") and device["name"].startswith("iPhone"):
                candidates.append((version, "Pro" in device["name"], device["name"]))

    if not candidates:
        print("No available iPhone simulator found", file=sys.stderr)
        return 1

    # Newest runtime wins; a Pro model breaks ties so the destination stays consistent.
    candidates.sort()
    print(candidates[-1][2])
    return 0


if __name__ == "__main__":
    sys.exit(main())
