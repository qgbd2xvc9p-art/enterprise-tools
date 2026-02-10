#!/usr/bin/env python3
import argparse
import datetime as _dt
import json
import os
import re
import subprocess
import sys
from typing import Any, Dict, Optional


def _title_from_id(value: str) -> str:
    return " ".join(part.capitalize() for part in re.split(r"[-_]+", value) if part)


def _dart_project_name(tool_id: str) -> str:
    sanitized = re.sub(r"[^a-z0-9_]+", "_", tool_id.lower().replace("-", "_"))
    sanitized = re.sub(r"_+", "_", sanitized).strip("_")
    if not sanitized or sanitized[0].isdigit():
        sanitized = f"tool_{sanitized}" if sanitized else "tool_app"
    return sanitized


def _infer_repo_slug() -> Optional[str]:
    try:
        remote = subprocess.check_output(
            ["git", "config", "--get", "remote.origin.url"], text=True
        ).strip()
    except Exception:
        return None

    if remote.startswith("git@github.com:"):
        slug = remote[len("git@github.com:") :]
    elif remote.startswith("https://github.com/"):
        slug = remote[len("https://github.com/") :]
    elif remote.startswith("ssh://git@github.com/"):
        slug = remote[len("ssh://git@github.com/") :]
    else:
        return None

    if slug.endswith(".git"):
        slug = slug[:-4]
    if "/" not in slug:
        return None
    return slug


def _ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def _write_tool_yaml(path: str, tool_id: str, version: str) -> None:
    content = (
        f"name: {tool_id}\n"
        f"version: {version}\n"
        "build:\n"
        "  windows: flutter build windows\n"
        "  macos: flutter build macos\n"
        "package:\n"
        "  windows: build/windows/x64/runner/Release\n"
        "  macos: build/macos/Build/Products/Release\n"
    )
    with open(path, "w", encoding="utf-8") as file:
        file.write(content)


def _load_registry(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        return {"generatedAt": "", "source": "script", "enterprises": []}
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def _save_registry(path: str, data: Dict[str, Any]) -> None:
    with open(path, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2, ensure_ascii=True)
        file.write("\n")


def _update_registry(
    registry_path: str,
    enterprise_id: str,
    enterprise_name: str,
    tool_id: str,
    tool_name: str,
    version: str,
    description: str,
    repo_slug: Optional[str],
    update_existing: bool,
) -> Dict[str, Any]:
    data = _load_registry(registry_path)
    data["generatedAt"] = _dt.date.today().isoformat()
    data["source"] = "script"

    enterprises = data.setdefault("enterprises", [])
    enterprise = next((e for e in enterprises if e.get("id") == enterprise_id), None)
    if enterprise is None:
        enterprise = {"id": enterprise_id, "name": enterprise_name, "tools": []}
        enterprises.append(enterprise)
    else:
        if enterprise_name and enterprise.get("name") != enterprise_name:
            enterprise["name"] = enterprise_name

    tools = enterprise.setdefault("tools", [])
    existing = next((t for t in tools if t.get("id") == tool_id), None)
    if existing and not update_existing:
        raise SystemExit(
            f"Tool '{tool_id}' already exists in registry. Use --update to overwrite."
        )

    asset_macos = f"{enterprise_id}-{tool_id}-{version}-macos.zip"
    asset_windows = f"{enterprise_id}-{tool_id}-{version}-windows.zip"
    if repo_slug:
        base = f"https://github.com/{repo_slug}/releases/latest/download"
        url_macos = f"{base}/{asset_macos}"
        url_windows = f"{base}/{asset_windows}"
    else:
        url_macos = ""
        url_windows = ""

    entry = {
        "id": tool_id,
        "name": tool_name,
        "version": version,
        "description": description,
        "platforms": {
            "macos": {"asset": asset_macos, "url": url_macos},
            "windows": {"asset": asset_windows, "url": url_windows},
        },
    }

    if existing:
        tools[tools.index(existing)] = entry
    else:
        tools.append(entry)

    return data


def _run_flutter_create(tool_dir: str, tool_id: str) -> None:
    project_name = _dart_project_name(tool_id)
    cmd = [
        "flutter",
        "create",
        ".",
        "--platforms=windows,macos",
        f"--project-name={project_name}",
        "--no-pub",
    ]
    subprocess.check_call(cmd, cwd=tool_dir)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create a new enterprise tool and update registry.json"
    )
    parser.add_argument("--enterprise-id", required=True)
    parser.add_argument("--enterprise-name")
    parser.add_argument("--tool-id", required=True)
    parser.add_argument("--tool-name")
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--description", default="")
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--init-flutter", action="store_true")
    parser.add_argument("--no-harmony-font", action="store_true")
    parser.add_argument("--repo", help="GitHub repo in owner/name form")

    args = parser.parse_args()

    enterprise_id = args.enterprise_id.strip()
    tool_id = args.tool_id.strip()
    if not enterprise_id or not tool_id:
        raise SystemExit("Enterprise ID and tool ID are required.")

    enterprise_name = args.enterprise_name or _title_from_id(enterprise_id)
    tool_name = args.tool_name or _title_from_id(tool_id)
    description = args.description or f"Tool for {enterprise_name}."

    tool_dir = os.path.join("tenants", enterprise_id, "tools", tool_id)
    _ensure_dir(tool_dir)

    tool_yaml = os.path.join(tool_dir, "tool.yaml")
    if os.path.exists(tool_yaml) and not args.update:
        raise SystemExit(
            f"{tool_yaml} already exists. Use --update to overwrite registry only."
        )
    if not os.path.exists(tool_yaml):
        _write_tool_yaml(tool_yaml, tool_id, args.version)

    if args.init_flutter:
        _run_flutter_create(tool_dir, tool_id)
        if not args.no_harmony_font:
            subprocess.check_call(
                [
                    sys.executable,
                    os.path.join("scripts", "apply_harmony_font.py"),
                    "--tool",
                    tool_dir,
                ]
            )

    repo_slug = args.repo or _infer_repo_slug()

    registry = _update_registry(
        registry_path="registry.json",
        enterprise_id=enterprise_id,
        enterprise_name=enterprise_name,
        tool_id=tool_id,
        tool_name=tool_name,
        version=args.version,
        description=description,
        repo_slug=repo_slug,
        update_existing=args.update,
    )
    _save_registry("registry.json", registry)

    app_registry = os.path.join("app", "assets", "registry.json")
    if os.path.exists(app_registry):
        _save_registry(app_registry, registry)

    if repo_slug is None:
        print("Warning: could not infer GitHub repo; URLs are empty.", file=sys.stderr)

    print(f"Created tool at {tool_dir}")
    print("Updated registry.json and app/assets/registry.json")


if __name__ == "__main__":
    main()
