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
