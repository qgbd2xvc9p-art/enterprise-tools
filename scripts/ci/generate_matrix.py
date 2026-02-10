#!/usr/bin/env python3
import json
import os
import subprocess
import sys

try:
    import yaml  # type: ignore
except Exception as exc:
    print("PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
    raise


def is_zero_sha(sha: str) -> bool:
    return sha == "0" * 40


def git_changed_files(before: str, after: str):
    if not before or is_zero_sha(before):
        return None
    try:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", before, after], text=True
        )
    except subprocess.CalledProcessError:
        return None
    lines = [line.strip() for line in out.splitlines() if line.strip()]
    return lines


def find_tool_yaml():
    for root, _dirs, files in os.walk("tenants"):
        if "tool.yaml" in files:
            yield os.path.join(root, "tool.yaml")


def tool_from_path(path: str):
    parts = path.split(os.sep)
    if "tenants" not in parts:
        return None
    idx = parts.index("tenants")
    if len(parts) < idx + 4:
        return None
    if parts[idx + 2] != "tools":
        return None
    enterprise = parts[idx + 1]
    tool = parts[idx + 3]
    return enterprise, tool


def load_yaml(path: str):
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    return data


def build_entry(tool_yaml: str):
    enterprise_tool = tool_from_path(tool_yaml)
    if not enterprise_tool:
        return None
    enterprise, tool = enterprise_tool
    data = load_yaml(tool_yaml)
    build = data.get("build", {}) or {}
    package = data.get("package", {}) or {}

    entry = {
        "enterprise": enterprise,
        "tool": tool,
        "name": data.get("name", tool),
        "version": str(data.get("version", "0.0.0")),
        "dir": os.path.dirname(tool_yaml).replace("\\", "/"),
        "build_windows": build.get("windows", "flutter build windows"),
        "build_macos": build.get("macos", "flutter build macos"),
        "package_windows": package.get(
            "windows", "build/windows/x64/runner/Release"
        ),
        "package_macos": package.get(
            "macos", "build/macos/Build/Products/Release"
        ),
    }
    apply_cmd = "python ../../../../scripts/apply_harmony_font.py --tool ."
    if "apply_harmony_font.py" not in entry["build_windows"]:
        entry["build_windows"] = f"{apply_cmd} && {entry['build_windows']}"
    if "apply_harmony_font.py" not in entry["build_macos"]:
        entry["build_macos"] = f"{apply_cmd} && {entry['build_macos']}"
    return entry


def collect_tool_yamls(build_all: bool, before: str, after: str):
    if build_all:
        return list(find_tool_yaml())

    changed = git_changed_files(before, after)
    if changed is None:
        return list(find_tool_yaml())

    tools = set()
    for path in changed:
        parts = path.split(os.sep)
        if "tenants" not in parts:
            continue
        idx = parts.index("tenants")
        if len(parts) < idx + 4:
            continue
        if parts[idx + 2] != "tools":
            continue
        tool_dir = os.sep.join(parts[: idx + 4])
        tool_yaml = os.path.join(tool_dir, "tool.yaml")
        if os.path.isfile(tool_yaml):
            tools.add(tool_yaml)

    return sorted(tools)


def main():
    build_all = os.environ.get("BUILD_ALL", "false").lower() == "true"
    before = os.environ.get("BEFORE", "")
    after = os.environ.get("AFTER", "")

    tool_yamls = collect_tool_yamls(build_all, before, after)

    matrix = {"include": []}
    for tool_yaml in tool_yamls:
        entry = build_entry(tool_yaml)
        if not entry:
            continue
        matrix["include"].append(
            {
                "os": "windows-latest",
                "platform": "windows",
                "build_cmd": entry["build_windows"],
                "package_dir": entry["package_windows"],
                **{k: entry[k] for k in ["enterprise", "tool", "name", "version", "dir"]},
            }
        )
        matrix["include"].append(
            {
                "os": "macos-latest",
                "platform": "macos",
                "build_cmd": entry["build_macos"],
                "package_dir": entry["package_macos"],
                **{k: entry[k] for k in ["enterprise", "tool", "name", "version", "dir"]},
            }
        )

    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as f:
            f.write(f"matrix={json.dumps(matrix)}\n")
            f.write(f"has_tools={'true' if matrix['include'] else 'false'}\n")
    else:
        print(json.dumps(matrix))


if __name__ == "__main__":
    main()
