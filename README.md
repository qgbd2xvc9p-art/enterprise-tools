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
