#!/usr/bin/env python3
"""Prepares a usable Xcode + iPhone simulator on a CI runner, and prints both.

A runner does not necessarily have an iPhone simulator ready to use: it can have iOS
runtimes installed with no *device* created against them, and `xcodebuild` can only
target devices. It may also carry an Xcode newer than its own macOS. So rather than
hoping a device exists, pick an Xcode, create a device against one of that Xcode's own
iOS runtimes (a too-new runtime is invisible to it), boot it, and address it by UDID —
which also sidesteps `simctl` state being shared between Xcodes.

Note that when this project still carried unused Firebase and RevenueCat package
references, every `xcodebuild` invocation stalled resolving that graph and listed no
iOS destinations at all. If destination enumeration ever goes strange again, check the
package graph before suspecting the simulator.

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


def boot(developer_dir: str, udid: str) -> None:
    """Boots the device and waits for it.

    A freshly created simulator can stay invisible to `xcodebuild -showdestinations`
    until CoreSimulator has actually brought it up, which is why enumeration is a
    diagnostic here rather than a gate — the build itself is the real test.
    """
    run(["xcrun", "simctl", "boot", udid], developer_dir, timeout=300)
    result = run(["xcrun", "simctl", "bootstatus", udid, "-b"], developer_dir, timeout=300)
    log(f"  boot status: {(result.stdout or result.stderr).strip().splitlines()[-1:] or ['(none)']}")


def report_destinations(developer_dir: str, udid: str) -> None:
    result = run(["xcodebuild", "-project", "HabitForge.xcodeproj",
                  "-scheme", "HabitForge", "-showdestinations"], developer_dir)
    listed = udid in result.stdout
    log(f"  xcodebuild lists this device: {listed}")
    if not listed:
        for line in result.stdout.splitlines():
            if "iOS Simulator" in line:
                log("    " + line.strip())


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

        boot(developer_dir, udid)
        report_destinations(developer_dir, udid)

        print(f"DEVELOPER_DIR={developer_dir}")
        print(f"DESTINATION=platform=iOS Simulator,id={udid}")
        return 0

    log("No installed Xcode could target a freshly created iPhone simulator")
    return 1


if __name__ == "__main__":
    sys.exit(main())
