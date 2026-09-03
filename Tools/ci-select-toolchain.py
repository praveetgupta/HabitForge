#!/usr/bin/env python3
"""Prepares a usable Xcode + iPhone simulator on a CI runner, and prints both.

GitHub's macOS runners have burned us three ways here, so this stops inferring and
arranges things explicitly:

  * The newest installed Xcode can be newer than the runner's macOS (Xcode 26.3 on
    macOS 15.7), a pairing Xcode does not support.
  * `xcrun simctl list runtimes` reporting iOS runtimes does not mean any iPhone
    *device* has been created against them — and `xcodebuild` can only target devices.
    With none, `-showdestinations` lists visionOS entries and a bare
    "Any iOS Simulator Device" placeholder, and every concrete destination fails.
  * `simctl` state is shared across Xcodes, so a device seen under one may be
    unusable by another.

So: pick an Xcode (preferring the 16.x line, which is the stable pairing for macOS 15),
then create a device against one of that Xcode's own iOS runtimes and address it by
UDID, which sidesteps name and OS ambiguity entirely.

Prints two shell-ready lines:

    DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer
    DESTINATION=platform=iOS Simulator,id=<udid>
"""

from __future__ import annotations

import glob
import json
import os
import re
import subprocess
import sys

DEVICE_PREFIX = "HabitForge-CI"


def log(message: str) -> None:
    print(message, file=sys.stderr)


def run(args, developer_dir, timeout=600):
    env = dict(os.environ, DEVELOPER_DIR=developer_dir)
    return subprocess.run(args, capture_output=True, text=True, env=env, timeout=timeout)


def version_of(path: str) -> tuple:
    numbers = tuple(int(p) for p in re.findall(r"\d+", os.path.basename(path)))
    return numbers or (0,)


def xcode_candidates() -> list:
    apps = glob.glob("/Applications/Xcode*.app")
    apps = [a for a in apps
            if os.path.isdir(os.path.join(a, "Contents/Developer/Platforms/iPhoneSimulator.platform"))]
    # Xcode 16.x first (the stable pairing for a macOS 15 runner), then the rest,
    # each group newest-first.
    sixteens = sorted((a for a in apps if version_of(a)[0] == 16), key=version_of, reverse=True)
    others = sorted((a for a in apps if version_of(a)[0] != 16), key=version_of, reverse=True)
    return sixteens + others


def ios_runtimes(developer_dir: str) -> list:
    result = run(["xcrun", "simctl", "list", "runtimes", "--json"], developer_dir)
    if result.returncode != 0:
        return []
    runtimes = []
    for runtime in json.loads(result.stdout).get("runtimes", []):
        if not runtime.get("isAvailable") or "iOS" not in runtime.get("name", ""):
            continue
        version = tuple(int(p) for p in re.findall(r"\d+", runtime.get("version", "0")))
        runtimes.append((version, runtime))
    runtimes.sort(key=lambda r: r[0], reverse=True)
    return [r[1] for r in runtimes]


def sdk_version(developer_dir: str) -> tuple:
    """The iOS Simulator SDK this Xcode ships, e.g. (18, 5) for Xcode 16.4.

    An Xcode can only target runtimes up to its own SDK, and `simctl` happily lists
    newer ones because its state is shared across every installed Xcode. Creating a
    device on a too-new runtime is exactly how CI ended up with a simulator that
    xcodebuild refused to acknowledge.
    """
    result = run(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"], developer_dir, timeout=120)
    if result.returncode != 0:
        return ()
    return tuple(int(p) for p in re.findall(r"\d+", result.stdout.strip()))


def existing_device(developer_dir: str, name: str) -> str | None:
    result = run(["xcrun", "simctl", "list", "devices", "--json"], developer_dir)
    if result.returncode != 0:
        return None
    for devices in json.loads(result.stdout).get("devices", {}).values():
        for device in devices:
            if device.get("name") == name and device.get("isAvailable"):
                return device["udid"]
    return None


def create_device(developer_dir: str, runtime: dict, name: str) -> str | None:
    """Creates an iPhone against `runtime`, trying its supported types newest-first."""
    supported = [t for t in runtime.get("supportedDeviceTypes", [])
                 if t.get("name", "").startswith("iPhone")]
    if not supported:
        result = run(["xcrun", "simctl", "list", "devicetypes", "--json"], developer_dir)
        if result.returncode == 0:
            supported = [t for t in json.loads(result.stdout).get("devicetypes", [])
                         if t.get("name", "").startswith("iPhone")]

    # Newest-looking model first, so CI logs name something current rather than an
    # iPhone 11 that happened to sort last.
    supported.sort(key=lambda t: (tuple(int(n) for n in re.findall(r"\d+", t["name"])) or (0,),
                                  "Pro" in t["name"]),
                   reverse=True)

    for device_type in supported:
        result = run(["xcrun", "simctl", "create", name,
                      device_type["identifier"], runtime["identifier"]], developer_dir)
        if result.returncode == 0:
            udid = result.stdout.strip()
            log(f"  created {device_type['name']} on {runtime['name']} ({udid})")
            return udid
    return None


def can_target(developer_dir: str, udid: str) -> bool:
    result = run(["xcodebuild", "-project", "HabitForge.xcodeproj",
                  "-scheme", "HabitForge", "-showdestinations"], developer_dir)
    if udid in result.stdout:
        return True
    log("  xcodebuild still does not list it. -showdestinations said:")
    for line in result.stdout.splitlines():
        if "iOS Simulator" in line:
            log("    " + line.strip())
    return False


def main() -> int:
    candidates = xcode_candidates()
    if not candidates:
        log("No Xcode with an iPhoneSimulator platform found")
        return 1

    for app in candidates:
        developer_dir = os.path.join(app, "Contents", "Developer")
        log(f"trying {app}")

        sdk = sdk_version(developer_dir)
        if not sdk:
            log("  no iphonesimulator SDK")
            continue
        log("  iphonesimulator SDK: " + ".".join(str(p) for p in sdk))

        runtimes = ios_runtimes(developer_dir)
        log("  iOS runtimes: " + (", ".join(r["name"] for r in runtimes) or "none"))
        runtimes = [r for r in runtimes
                    if tuple(int(p) for p in re.findall(r"\d+", r.get("version", "0"))) <= sdk]
        if not runtimes:
            log("  none of those runtimes are within this Xcode's SDK")
            continue

        udid = None
        for runtime in runtimes:
            # Name the device after its runtime: a device built for iOS 26.2 must never be
            # handed to an Xcode whose SDK stops at 18.5.
            name = f"{DEVICE_PREFIX}-{runtime['identifier'].rsplit('.', 1)[-1]}"
            udid = existing_device(developer_dir, name)
            if udid:
                log(f"  reusing existing {name} ({udid})")
                break
            udid = create_device(developer_dir, runtime, name)
            if udid:
                break
        if not udid:
            log("  could not create an iPhone simulator")
            continue

        if not can_target(developer_dir, udid):
            continue

        print(f"DEVELOPER_DIR={developer_dir}")
        print(f"DESTINATION=platform=iOS Simulator,id={udid}")
        return 0

    log("No installed Xcode could target a freshly created iPhone simulator")
    return 1


if __name__ == "__main__":
    sys.exit(main())
