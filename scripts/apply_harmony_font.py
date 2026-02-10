#!/usr/bin/env python3
import argparse
import os
import re
import sys
import urllib.request
import zipfile
from typing import Iterable, List

HARMONY_FONT_FAMILY = "HarmonyOS Sans"
HARMONY_FONT_URL = (
    "https://developer.huawei.com/images/download/general/HarmonyOS-Sans.zip"
)


def _is_flutter_tool(tool_dir: str) -> bool:
    return os.path.isfile(os.path.join(tool_dir, "pubspec.yaml"))


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _download_font_zip(cache_dir: str) -> str:
    _ensure_dir(cache_dir)
    zip_path = os.path.join(cache_dir, "HarmonyOS-Sans.zip")
    if os.path.isfile(zip_path) and os.path.getsize(zip_path) > 0:
        return zip_path
    with urllib.request.urlopen(HARMONY_FONT_URL) as resp, open(
        zip_path, "wb"
    ) as out:
        out.write(resp.read())
    return zip_path


def _extract_fonts(zip_path: str, dest_dir: str) -> List[str]:
    _ensure_dir(dest_dir)
    extracted = []
    with zipfile.ZipFile(zip_path, "r") as zf:
        for name in zf.namelist():
            lower = name.lower()
            if not (lower.endswith(".ttf") or lower.endswith(".otf")):
                continue
            data = zf.read(name)
            filename = os.path.basename(name)
            if not filename:
                continue
            out_path = os.path.join(dest_dir, filename)
            with open(out_path, "wb") as out:
                out.write(data)
            extracted.append(out_path)
    return extracted


def _font_assets(dest_dir: str) -> List[str]:
    assets = []
    if not os.path.isdir(dest_dir):
        return assets
    for name in sorted(os.listdir(dest_dir)):
        lower = name.lower()
        if lower.endswith(".ttf") or lower.endswith(".otf"):
            assets.append(f"assets/fonts/harmonyos-sans/{name}")
    return assets


def _find_flutter_block(lines: List[str]) -> int:
    for idx, line in enumerate(lines):
        if line.strip() == "flutter:":
            return idx
    return -1


def _block_end(lines: List[str], start_idx: int) -> int:
    base_indent = len(lines[start_idx]) - len(lines[start_idx].lstrip())
    for i in range(start_idx + 1, len(lines)):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if indent <= base_indent:
            return i
    return len(lines)


def _ensure_fonts_in_pubspec(pubspec_path: str, assets: Iterable[str]) -> None:
    with open(pubspec_path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines()

    flutter_idx = _find_flutter_block(lines)
    if flutter_idx == -1:
        lines.append("")
        lines.append("flutter:")
        flutter_idx = len(lines) - 1

    if any("family: " + HARMONY_FONT_FAMILY in line for line in lines):
        return

    end_idx = _block_end(lines, flutter_idx)
    flutter_indent = len(lines[flutter_idx]) - len(lines[flutter_idx].lstrip())
    base = " " * (flutter_indent + 2)
    item = " " * (flutter_indent + 4)
    nested = " " * (flutter_indent + 6)

    font_block = [f"{base}fonts:", f"{item}- family: {HARMONY_FONT_FAMILY}", f"{nested}fonts:"]
    for asset in assets:
        font_block.append(f"{nested}  - asset: {asset}")

    if end_idx == len(lines):
        lines.append("")
        lines.extend(font_block)
    else:
        lines[end_idx:end_idx] = [""] + font_block

    with open(pubspec_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def _ensure_dart_io_import(text: str) -> str:
    if re.search(r"^import 'dart:io';", text, re.M):
        return text
    lines = text.splitlines()
    insert_at = 0
    for idx, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = idx + 1
    lines.insert(insert_at, "import 'dart:io';")
    return "\n".join(lines)


def _ensure_font_in_main(main_path: str) -> None:
    with open(main_path, "r", encoding="utf-8") as f:
        text = f.read()

    if HARMONY_FONT_FAMILY in text:
        return

    text = _ensure_dart_io_import(text)
    lines = text.splitlines()
    theme_idx = -1
    for idx, line in enumerate(lines):
        if "ThemeData(" in line:
            theme_idx = idx
            break
    if theme_idx == -1:
        with open(main_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        return

    if any("fontFamily:" in line for line in lines[theme_idx : theme_idx + 10]):
        with open(main_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        return

    indent = re.match(r"\s*", lines[theme_idx]).group(0)
    lines.insert(
        theme_idx + 1,
        f"{indent}  fontFamily: Platform.isWindows ? '{HARMONY_FONT_FAMILY}' : null,",
    )

    with open(main_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def apply_to_tool(tool_dir: str) -> str:
    if not _is_flutter_tool(tool_dir):
        return "skip_non_flutter"
    pubspec = os.path.join(tool_dir, "pubspec.yaml")
    main_dart = os.path.join(tool_dir, "lib", "main.dart")
    if not os.path.isfile(pubspec) or not os.path.isfile(main_dart):
        return "skip_missing"

    cache_dir = os.path.join(os.path.dirname(__file__), ".cache")
    zip_path = _download_font_zip(cache_dir)
    font_dir = os.path.join(tool_dir, "assets", "fonts", "harmonyos-sans")
    _extract_fonts(zip_path, font_dir)
    assets = _font_assets(font_dir)
    if not assets:
        return "skip_no_fonts"
    _ensure_fonts_in_pubspec(pubspec, assets)
    _ensure_font_in_main(main_dart)
    return "applied"


def find_tools(root: str) -> Iterable[str]:
    for dirpath, dirnames, filenames in os.walk(root):
        if "tool.yaml" in filenames and "pubspec.yaml" in filenames:
            yield dirpath


def main() -> None:
    parser = argparse.ArgumentParser(description="Apply HarmonyOS Sans to tools")
    parser.add_argument("--tool", help="Tool directory")
    parser.add_argument("--all", action="store_true", help="Scan tenants/")
    args = parser.parse_args()

    targets = []
    if args.tool:
        targets.append(os.path.abspath(args.tool))
    if args.all:
        targets.extend(find_tools("tenants"))
    if not targets:
        raise SystemExit("Provide --tool <dir> or --all")

    changed = 0
    skipped = 0
    for tool_dir in targets:
        status = apply_to_tool(tool_dir)
        if status == "applied":
            changed += 1
            print(f"Applied HarmonyOS Sans to: {tool_dir}")
        elif status == "skip_non_flutter":
            skipped += 1
            print(f"Skip (non-Flutter): {tool_dir}")
        else:
            skipped += 1
            print(f"Skip: {tool_dir}")
    if changed == 0 and skipped > 0:
        print("No Flutter tools updated.")


if __name__ == "__main__":
    main()
