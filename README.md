# enterprise-tools

Multi-tenant tools repository.

## Structure

```
tenants/<enterprise_id>/tools/<tool_id>/
  tool.yaml
  <flutter project files>
```

## tool.yaml

```yaml
name: sample-tool
version: 0.1.0
build:
  windows: flutter build windows
  macos: flutter build macos
package:
  windows: build/windows/x64/runner/Release
  macos: build/macos/Build/Products/Release
```

- `build.*` are the commands run inside the tool folder.
- `package.*` are directories to package into zip artifacts.

## CI

GitHub Actions builds changed tools on push and creates a Release with zip assets.

- Windows asset: `<enterprise>-<tool>-<version>-windows.zip`
- macOS asset: `<enterprise>-<tool>-<version>-macos.zip`

## Desktop Console App

The desktop console lives in `app/`.

- Registry source: `registry.json`
- Fallback registry asset: `app/assets/registry.json`
- Demo users: `app/assets/users.json`

### 应用说明（文字版）

企业工具台是一款面向企业内部的桌面工具管理平台，用于集中管理、下载、更新与运行各类工具。
它把分散的工具入口统一到一个界面里，提升部署效率与使用体验。

主要功能

- 企业工具集中管理与搜索
- 支持下载工具 / 本地工具 / 命令行工具
- 已安装工具可自动更新（可在设置中开关）
- 支持本地模式与远程（GitHub）模式

使用步骤

1. 在左侧企业列表选择企业。
2. 右侧工具区可搜索名称/描述并查看工具详情。
3. 下载工具点击“下载/更新”，本地工具点击“添加”。
4. 下载完成后可点击“打开/运行”。

添加工具步骤

1. 点击“新增工具”，选择所属企业。
2. 填写工具名称、版本与描述。
3. 选择工具类型并补充对应信息：
   - 下载工具：填写下载地址或选择文件上传（需 GitHub 权限）。
   - 本地工具：选择本机文件或文件夹路径。
   - 命令行工具：填写命令、参数与工作目录。
4. 点击“保存”，工具将出现在列表中。

提示

- 本地工具仅对当前电脑有效，不会上传到远端。
- 需要 GitHub 权限的功能请在“设置”中配置访问令牌。
- 自动更新默认开启，可在“设置”中关闭。

### Tool Types (embedded)

Each tool in `registry.json` can declare a `type`:

- `download` (default): download/update a zip asset
- `cli`: run a command and show output in a modal console

Example:
```json
{
  "id": "my-tool",
  "name": "My Tool",
  "version": "1.0.0",
  "type": "cli",
  "command": "python",
  "args": ["tools/my_tool/main.py"],
  "workingDir": "tools/my_tool"
}
```

## Create a New Tool (Script)

```
python scripts/create_tool.py \\
  --enterprise-id acme-inc \\
  --enterprise-name \"Acme Inc\" \\
  --tool-id report-tool \\
  --tool-name \"Report Tool\" \\
  --version 0.1.0 \\
  --description \"Internal reporting tool\" \\
  --init-flutter
```

Options:
- `--update`: overwrite registry entry if tool exists
- `--repo owner/name`: override GitHub repo slug for release URLs
- `--no-harmony-font`: skip applying HarmonyOS Sans for new Flutter tools

## HarmonyOS Sans for Tools

Windows builds of Flutter tools should use HarmonyOS Sans. The CI build
pipeline applies the font automatically before building. For local builds,
run:

```
python scripts/apply_harmony_font.py --all
```

This script downloads the font zip, adds assets to each Flutter tool, updates
`pubspec.yaml`, and injects the Windows-only font setting into `lib/main.dart`.
