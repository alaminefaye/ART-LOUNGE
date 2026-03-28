#!/usr/bin/env python3
"""Ajoute le namespace AGP 8+ au plugin blue_thermal_printer dans le pub-cache."""
from __future__ import annotations

import os
from pathlib import Path

NS = "    namespace 'id.kakzaki.blue_thermal_printer'\n"


def main() -> None:
    root = Path(os.environ.get("PUB_CACHE", Path.home() / ".pub-cache")) / "hosted/pub.dev"
    if not root.is_dir():
        print("Pub cache introuvable:", root)
        return
    for build in root.glob("blue_thermal_printer-*/android/build.gradle"):
        text = build.read_text(encoding="utf-8")
        if "namespace 'id.kakzaki.blue_thermal_printer'" in text:
            print("Déjà patché:", build)
            continue
        if "android {" not in text:
            continue
        lines = text.splitlines(keepends=True)
        out: list[str] = []
        done = False
        for line in lines:
            out.append(line)
            if not done and line.strip() == "android {":
                out.append(NS)
                done = True
        if done:
            build.write_text("".join(out), encoding="utf-8")
            print("Patch appliqué:", build)
        else:
            print("Structure inattendue:", build)


if __name__ == "__main__":
    main()
