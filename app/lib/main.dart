import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String registryUrl =
    'https://raw.githubusercontent.com/qgbd2xvc9p-art/enterprise-tools/main/registry.json';

void main() {
  runApp(const EnterpriseToolsApp());
}

class EnterpriseToolsApp extends StatefulWidget {
  const EnterpriseToolsApp({super.key});

  @override
  State<EnterpriseToolsApp> createState() => _EnterpriseToolsAppState();
}

class _EnterpriseToolsAppState extends State<EnterpriseToolsApp> {
  User? _user;

  void _handleLogin(User user) {
    setState(() {
      _user = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF0E3A53),
        onPrimary: Color(0xFFF7F4EE),
        secondary: Color(0xFFF4C07A),
        onSecondary: Color(0xFF1B1A17),
        error: Color(0xFFB94A48),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFFF7F4EE),
        onSurface: Color(0xFF1B1A17),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F4EE),
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13, height: 1.4),
      ),
    );

    return MaterialApp(
      title: '企业工具台',
      theme: theme,
      home: _user == null
          ? LoginScreen(onLogin: _handleLogin)
          : HomeScreen(user: _user!, onLogout: _handleLogout),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<User> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.authenticate(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _error = '用户名或密码错误。';
          _loading = false;
        });
        return;
      }
      widget.onLogin(user);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = '登录失败：${err.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E3A53), Color(0xFF1D6B7F), Color(0xFFF4C07A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: isCompact
                  ? _buildCompact(context)
                  : Row(
                      children: [
                        Expanded(child: _buildIntro(context)),
                        const SizedBox(width: 32),
                        SizedBox(width: 360, child: _buildCard(context)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIntro(context),
        const SizedBox(height: 24),
        _buildCard(context),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '企业工具台',
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          '一个入口管理所有企业工具。\n下载、更新、合规一站完成。',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _Tag(label: '桌面优先'),
            _Tag(label: '自动更新'),
            _Tag(label: '权限控制'),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '登录',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB94A48)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('进入控制台'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '演示账号：admin/admin123，example/example123，acme/acme123',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user, required this.onLogout});

  final User user;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Registry? _registry;
  String? _selectedEnterpriseId;
  bool _loading = true;
  String? _error;
  Map<String, InstalledEntry> _installed = {};
  Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloading = {};
  GitHubSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (force) {
        RegistryService.clearCache();
      }
      final settings = await LocalStore.loadSettings();
      final registry = await RegistryService.loadRegistry(settings: settings);
      final installed = await LocalStore.loadInstalled();
      final visible = _filterEnterprises(registry.enterprises);
      setState(() {
        _registry = registry;
        _installed = installed;
        _settings = settings;
        _selectedEnterpriseId =
            visible.isNotEmpty ? visible.first.id : null;
        _loading = false;
      });
    } catch (err) {
      setState(() {
        _error = '加载工具清单失败：${err.toString()}';
        _loading = false;
      });
    }
  }

  List<Enterprise> _filterEnterprises(List<Enterprise> enterprises) {
    if (widget.user.isAdmin || widget.user.enterprises.contains('*')) {
      return enterprises;
    }
    return enterprises
        .where((enterprise) => widget.user.enterprises.contains(enterprise.id))
        .toList();
  }

  Future<void> _downloadTool(Tool tool) async {
    final platformKey = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
            ? 'macos'
            : 'unknown';
    final platform = tool.platforms[platformKey];
    if (platform == null) {
      _showSnack('该工具不支持当前平台。');
      return;
    }

    final key = '${tool.enterpriseId}/${tool.id}';
    setState(() {
      _downloading[key] = true;
      _downloadProgress[key] = 0;
    });

    try {
      final entry = await DownloadService.downloadTool(
        tool: tool,
        platform: platform,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[key] = progress;
          });
        },
      );
      final updated = Map<String, InstalledEntry>.from(_installed);
      updated[key] = entry;
      await LocalStore.saveInstalled(updated);
      if (!mounted) return;
      setState(() {
        _installed = updated;
        _downloading.remove(key);
      });
      _showSnack('已下载到：${entry.path}');
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _downloading.remove(key);
      });
      _showSnack('下载失败：${err.toString()}');
    }
  }

  Future<void> _installLocalTool(Tool tool) async {
    final path = tool.localPath;
    if (path == null || path.trim().isEmpty) {
      _showSnack('未配置本地路径。');
      return;
    }
    String? bookmark;
    bool accessStarted = false;
    final key = '${tool.enterpriseId}/${tool.id}';
    setState(() {
      _downloading[key] = true;
      _downloadProgress[key] = 0;
    });
    try {
      if (Platform.isMacOS) {
        bookmark = await LocalStore.loadBookmark(path);
        if (bookmark == null || bookmark.isEmpty) {
          throw Exception('未授权访问该路径，请重新选择文件/文件夹');
        }
        accessStarted = await BookmarkService.startAccess(bookmark);
        if (!accessStarted) {
          throw Exception('无法访问该路径，请重新选择文件/文件夹');
        }
      }
      final sourceFile = File(path);
      final sourceDir = Directory(path);
      if (!await sourceFile.exists() && !await sourceDir.exists()) {
        throw Exception('本地路径不存在：$path');
      }

      final downloadDir = await LocalStore.downloadDirectory(
        enterpriseId: tool.enterpriseId,
        toolId: tool.id,
      );
      await downloadDir.create(recursive: true);

      final name = _basename(path);
      final destinationPath = '${downloadDir.path}/$name';
      final destFile = File(destinationPath);
      final destDir = Directory(destinationPath);

      if (await sourceFile.exists()) {
        await _copyFilePreserve(sourceFile, destFile.path);
      } else {
        if (await destDir.exists()) {
          await destDir.delete(recursive: true);
        }
        await _copyDirectoryPreserve(sourceDir, destDir);
      }

      final entry = InstalledEntry(
        version: tool.version,
        path: destinationPath,
        updatedAt: DateTime.now().toIso8601String(),
      );
      final updated = Map<String, InstalledEntry>.from(_installed);
      updated[key] = entry;
      await LocalStore.saveInstalled(updated);
      if (!mounted) return;
      setState(() {
        _installed = updated;
        _downloading.remove(key);
      });
      _showSnack('已添加到本地：$destinationPath');
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _downloading.remove(key);
      });
      if (err is FileSystemException &&
          err.osError?.errorCode == 1 &&
          Platform.isMacOS) {
        _showSnack('没有权限访问该路径，请用“编辑工具→选择文件/文件夹”重新授权。');
      } else {
        _showSnack('添加失败：${err.toString()}');
      }
    } finally {
      if (accessStarted && bookmark != null) {
        try {
          await BookmarkService.stopAccess(bookmark);
        } catch (_) {}
      }
    }
  }

  Future<void> _openInstalledTool(InstalledEntry entry) async {
    final path = entry.path;
    if (path.trim().isEmpty) {
      _showSnack('未找到可打开的路径。');
      return;
    }
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.notFound) {
      _showSnack('路径不存在，请重新安装工具。');
      return;
    }
    final lower = path.toLowerCase();
    if (lower.endsWith('.zip')) {
      _showSnack('这是压缩包，请先解压后再运行。');
      return;
    }
    try {
      _showSnack('正在打开，请稍候…');
      if (Platform.isMacOS) {
        final result = await Process.run('open', [path], runInShell: true);
        if (result.exitCode != 0) {
          _showSnack('打开失败：${result.stderr.toString()}');
        } else {
          _showSnack('已尝试打开，如无响应请在保存位置手动打开。');
        }
        return;
      }
      if (Platform.isWindows) {
        if (entityType == FileSystemEntityType.directory) {
          await Process.run('explorer', [path], runInShell: true);
        } else {
          await Process.run('cmd', ['/c', 'start', '', path],
              runInShell: true);
        }
        return;
      }
      await Process.run('xdg-open', [path], runInShell: true);
    } catch (err) {
      _showSnack('打开失败：${err.toString()}');
    }
  }

  void _runCliTool(Tool tool) {
    final command = tool.command;
    if (command == null || command.trim().isEmpty) {
      _showSnack('该工具未配置命令。');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CliToolDialog(
        title: tool.name,
        command: command,
        args: tool.args,
        workingDir: tool.workingDir,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openSettings() async {
    final current = _settings ?? GitHubSettings.defaultSettings();
    final result = await showDialog<GitHubSettings>(
      context: context,
      builder: (context) => GitHubSettingsDialog(settings: current),
    );
    if (result != null) {
      await LocalStore.saveSettings(result);
      setState(() {
        _settings = result;
      });
      _showSnack('设置已保存。');
    }
  }

  Future<void> _openAddEnterprise() async {
    final registry = _registry;
    if (registry == null) return;
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => AddEnterpriseDialog(existing: registry.enterprises),
    );
    if (result == null) return;
    if (result.localOnly) {
      await _saveLocalRegistryUpdate((data) {
        data.enterprises.add(result);
      });
      return;
    }
    await _saveRegistryUpdate((data) {
      data.enterprises.add(result.copyWith(localOnly: false));
    });
  }

  Future<void> _openEditEnterprise(Enterprise enterprise) async {
    final result = await showDialog<Enterprise>(
      context: context,
      builder: (context) => EditEnterpriseDialog(enterprise: enterprise),
    );
    if (result == null) return;
    if (enterprise.localOnly) {
      await _saveLocalRegistryUpdate((data) {
        final index = data.enterprises.indexWhere((e) => e.id == enterprise.id);
        if (index < 0) return;
        final target = data.enterprises[index];
        data.enterprises[index] = target.copyWith(name: result.name);
      });
      return;
    }
    await _saveRegistryUpdate((data) {
      final index = data.enterprises.indexWhere((e) => e.id == enterprise.id);
      if (index < 0) return;
      final target = data.enterprises[index];
      data.enterprises[index] = target.copyWith(name: result.name);
    });
  }

  Future<void> _openDeleteEnterprise(Enterprise enterprise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '删除企业',
        message: '确定要删除 ${enterprise.name} 吗？该企业下的工具也会被移除。',
      ),
    );
    if (confirmed != true) return;
    if (enterprise.localOnly) {
      await _saveLocalRegistryUpdate((data) {
        data.enterprises.removeWhere((e) => e.id == enterprise.id);
      });
    } else {
      await _saveRegistryUpdate((data) {
        data.enterprises.removeWhere((e) => e.id == enterprise.id);
      });
    }
    if (_selectedEnterpriseId == enterprise.id) {
      setState(() {
        _selectedEnterpriseId =
            _registry?.enterprises.isNotEmpty == true ? _registry!.enterprises.first.id : null;
      });
    }
  }

  Future<void> _openAddTool() async {
    final registry = _registry;
    if (registry == null) return;
    final result = await showDialog<Tool>(
      context: context,
      builder: (context) => AddToolDialog(
        enterprises: registry.enterprises,
        selectedEnterpriseId: _selectedEnterpriseId,
        settings: _settings,
      ),
    );
    if (result == null) return;
    if (result.localOnly) {
      final name = registry.enterprises
          .firstWhere(
            (e) => e.id == result.enterpriseId,
            orElse: () => Enterprise.empty(),
          )
          .name;
      await _saveLocalRegistryUpdate((data) {
        final enterprise = data.enterprises.firstWhere(
          (e) => e.id == result.enterpriseId,
          orElse: () => Enterprise.empty(),
        );
        if (enterprise.id.isEmpty) {
          data.enterprises.add(
            Enterprise(
              id: result.enterpriseId,
              name: name.isNotEmpty ? name : result.enterpriseId,
              tools: [result],
              localOnly: true,
            ),
          );
        } else {
          enterprise.tools.add(result);
        }
      });
      return;
    }
    await _saveRegistryUpdate((data) {
      final enterprise = data.enterprises.firstWhere(
        (e) => e.id == result.enterpriseId,
        orElse: () => Enterprise.empty(),
      );
      if (enterprise.id.isEmpty) {
        data.enterprises.add(
          Enterprise(id: result.enterpriseId, name: result.enterpriseId, tools: [result]),
        );
      } else {
        enterprise.tools.add(result.copyWith(localOnly: false));
      }
    });
  }

  Future<void> _openEditTool(Tool tool) async {
    final result = await showDialog<Tool>(
      context: context,
      builder: (context) => EditToolDialog(
        tool: tool,
        enterprises: _registry?.enterprises ?? [],
        settings: _settings,
      ),
    );
    if (result == null) return;
    if (tool.localOnly) {
      await _saveLocalRegistryUpdate((data) {
        final enterprise = data.enterprises.firstWhere(
          (e) => e.id == tool.enterpriseId,
          orElse: () => Enterprise.empty(),
        );
        if (enterprise.id.isEmpty) return;
        final index = enterprise.tools.indexWhere((t) => t.id == tool.id);
        if (index >= 0) {
          enterprise.tools[index] = result;
        }
      });
      return;
    }
    await _saveRegistryUpdate((data) {
      final enterprise = data.enterprises.firstWhere(
        (e) => e.id == tool.enterpriseId,
        orElse: () => Enterprise.empty(),
      );
      if (enterprise.id.isEmpty) return;
      final index = enterprise.tools.indexWhere((t) => t.id == tool.id);
      if (index >= 0) {
        enterprise.tools[index] = result.copyWith(localOnly: false);
      }
    });
  }

  Future<void> _openDeleteTool(Tool tool) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: '删除工具',
        message: '确定要删除 ${tool.name} 吗？',
      ),
    );
    if (confirmed != true) return;
    if (tool.localOnly) {
      await _saveLocalRegistryUpdate((data) {
        final enterprise = data.enterprises.firstWhere(
          (e) => e.id == tool.enterpriseId,
          orElse: () => Enterprise.empty(),
        );
        enterprise.tools.removeWhere((t) => t.id == tool.id);
      });
      return;
    }
    await _saveRegistryUpdate((data) {
      final enterprise = data.enterprises.firstWhere(
        (e) => e.id == tool.enterpriseId,
        orElse: () => Enterprise.empty(),
      );
      enterprise.tools.removeWhere((t) => t.id == tool.id);
    });
  }

  Future<void> _saveRegistryUpdate(void Function(Registry data) mutate) async {
    final registry = _registry;
    final settings = _settings;
    if (registry == null) return;
    if (settings == null || !settings.isValid) {
      _showSnack('请先在“设置”中配置 GitHub 权限。');
      return;
    }
    final updated = registry.copy();
    mutate(updated);
    try {
      await GitHubRegistryWriter.updateRegistry(
        settings: settings,
        registry: updated.remoteOnly(),
      );
      RegistryService.clearCache();
      final refreshed = await RegistryService.loadRegistry(settings: settings);
      setState(() {
        _registry = refreshed;
      });
      _showSnack('已提交到 GitHub。');
    } catch (err) {
      _showSnack('提交失败：${err.toString()}');
    }
  }

  Future<void> _saveLocalRegistryUpdate(void Function(Registry data) mutate) async {
    final localRegistry = await LocalStore.loadLocalRegistry();
    final updated = localRegistry.copy();
    mutate(updated);
    await LocalStore.saveLocalRegistry(updated);
    RegistryService.clearCache();
    final refreshed = await RegistryService.loadRegistry(settings: _settings);
    setState(() {
      _registry = refreshed;
    });
    _showSnack('已保存到本地。');
  }

  @override
  Widget build(BuildContext context) {
    final registry = _registry;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F4EE), Color(0xFFE3EDF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                        : registry == null
                        ? const Center(child: Text('未找到工具清单。'))
                        : _buildContent(registry, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFB94A48)),
          const SizedBox(height: 12),
          Text(_error ?? '未知错误'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildContent(Registry registry, ThemeData theme) {
    final enterprises = _filterEnterprises(registry.enterprises);
    final selected = enterprises
        .firstWhere((e) => e.id == _selectedEnterpriseId, orElse: () {
      return enterprises.isNotEmpty ? enterprises.first : Enterprise.empty();
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: _buildSidebar(theme, enterprises),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildToolsPanel(theme, selected),
        ),
      ],
    );
  }

  Widget _buildSidebar(ThemeData theme, List<Enterprise> enterprises) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('企业列表', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final enterprise = enterprises[index];
                final selected = enterprise.id == _selectedEnterpriseId;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEnterpriseId = enterprise.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF0E3A53)
                          : const Color(0xFFF7F4EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            enterprise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (enterprise.localOnly)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFFDCE6EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '本地',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    selected ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          tooltip: '更多',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditEnterprise(enterprise);
                            } else if (value == 'delete') {
                              _openDeleteEnterprise(enterprise);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑')),
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                          icon: Icon(
                            Icons.more_horiz,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: enterprises.length,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EDF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.username,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(onPressed: widget.onLogout, child: const Text('退出登录'))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(ThemeData theme, Enterprise enterprise) {
    if (enterprise.id.isEmpty) {
      return Center(
        child: Text(
          '没有可访问的企业。',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${enterprise.name} 的工具',
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '当前平台：${Platform.isMacOS ? 'macOS' : Platform.isWindows ? 'Windows' : '未知'}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _load(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openAddEnterprise,
              icon: const Icon(Icons.domain_add),
              label: const Text('新增企业'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: enterprise.id.isEmpty ? null : _openAddTool,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('新增工具'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _openSettings,
              tooltip: '设置',
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: enterprise.tools.length,
            itemBuilder: (context, index) {
              final tool = enterprise.tools[index];
              final card = _buildToolCard(theme, tool);
              return _StaggeredReveal(index: index, child: card);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(ThemeData theme, Tool tool) {
    final key = '${tool.enterpriseId}/${tool.id}';
    final installed = _installed[key];
    final hasUpdate = installed != null &&
        compareVersions(installed.version, tool.version) < 0;
    final isDownloading = _downloading[key] == true;
    final progress = _downloadProgress[key] ?? 0;
    final toolType = tool.type.toLowerCase();
    final isDownloadTool = toolType == 'download';
    final isCliTool = toolType == 'cli';
    final isLocalTool = toolType == 'local';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tool.name, style: theme.textTheme.titleLarge),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E3A53),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v${tool.version}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: '更多',
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditTool(tool);
                  } else if (value == 'delete') {
                    _openDeleteTool(tool);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tool.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: isDownloadTool
                    ? (installed == null
                        ? '未安装'
                        : '已安装 v${installed.version}')
                    : isCliTool
                        ? '命令行工具'
                        : isLocalTool
                            ? '本地工具'
                            : '内嵌工具',
              ),
              if (tool.localOnly) const _InfoChip(label: '仅本地'),
              if (isDownloadTool && hasUpdate)
                const _InfoChip(label: '有新版本', accent: true),
              if ((isDownloadTool || isLocalTool) && installed != null)
                _InfoChip(label: '保存位置：${installed.path}'),
              if (isCliTool && tool.command != null)
                _InfoChip(label: tool.command!),
              if (isLocalTool && tool.localPath != null)
                _InfoChip(label: tool.localPath!),
            ],
          ),
          const SizedBox(height: 16),
          if (isDownloadTool && isDownloading)
            LinearProgressIndicator(
              value: progress == 0 ? null : progress,
              minHeight: 6,
            ),
          if (isDownloadTool && isDownloading) const SizedBox(height: 12),
          Row(
            children: [
              if (isDownloadTool)
                FilledButton(
                  onPressed: isDownloading ? null : () => _downloadTool(tool),
                  child: Text(installed == null
                      ? '下载'
                      : hasUpdate
                          ? '更新'
                          : '重新下载'),
                )
              else if (isCliTool)
                FilledButton(
                  onPressed: () => _runCliTool(tool),
                  child: const Text('运行'),
                )
              else if (isLocalTool)
                FilledButton(
                  onPressed: () => _installLocalTool(tool),
                  child: Text(installed == null ? '添加' : '重新添加'),
                )
              else
                FilledButton(
                  onPressed: () => _showSnack('此版本未启用网页工具。'),
                  child: const Text('不可用'),
                ),
              const SizedBox(width: 12),
              if ((isDownloadTool || isLocalTool) && installed != null)
                OutlinedButton.icon(
                  onPressed: () => _openInstalledTool(installed),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('打开/运行'),
                ),
              const SizedBox(width: 12),
              if ((isDownloadTool || isLocalTool) && installed != null)
                Text(
                  installed.updatedAt,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFF4C07A) : const Color(0xFFE3EDF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _StaggeredReveal extends StatelessWidget {
  const _StaggeredReveal({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class GitHubSettingsDialog extends StatefulWidget {
  const GitHubSettingsDialog({super.key, required this.settings});

  final GitHubSettings settings;

  @override
  State<GitHubSettingsDialog> createState() => _GitHubSettingsDialogState();
}

class _GitHubSettingsDialogState extends State<GitHubSettingsDialog> {
  late final TextEditingController _tokenController;
  late final TextEditingController _repoController;
  late final TextEditingController _branchController;
  late final TextEditingController _registryPathController;
  late final TextEditingController _assetRegistryPathController;
  late final TextEditingController _uploadBasePathController;
  String? _error;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.settings.token);
    _repoController = TextEditingController(text: widget.settings.repo);
    _branchController = TextEditingController(text: widget.settings.branch);
    _registryPathController =
        TextEditingController(text: widget.settings.registryPath);
    _assetRegistryPathController =
        TextEditingController(text: widget.settings.assetRegistryPath);
    _uploadBasePathController =
        TextEditingController(text: widget.settings.uploadBasePath);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _repoController.dispose();
    _branchController.dispose();
    _registryPathController.dispose();
    _assetRegistryPathController.dispose();
    _uploadBasePathController.dispose();
    super.dispose();
  }

  void _save() {
    final token = _tokenController.text.trim();
    final repo = _repoController.text.trim();
    if (token.isEmpty || repo.isEmpty) {
      setState(() {
      _error = '访问令牌和仓库不能为空。';
      });
      return;
    }
    Navigator.of(context).pop(
      GitHubSettings(
        token: token,
        repo: repo,
        branch: _branchController.text.trim().isEmpty
            ? 'main'
            : _branchController.text.trim(),
        registryPath: _registryPathController.text.trim().isEmpty
            ? 'registry.json'
            : _registryPathController.text.trim(),
        assetRegistryPath: _assetRegistryPathController.text.trim(),
        uploadBasePath: _uploadBasePathController.text.trim().isEmpty
            ? 'tools'
            : _uploadBasePathController.text.trim(),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final token = _tokenController.text.trim();
    final repo = _repoController.text.trim();
    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'enterprise-tools-app',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = repo.isNotEmpty
        ? Uri.parse('https://api.github.com/repos/$repo')
        : Uri.parse('https://api.github.com');
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() => _testResult = '连接成功（${response.statusCode}）');
      } else {
        setState(
          () => _testResult =
              '连接失败：${response.statusCode} ${_truncate(response.body)}',
        );
      }
    } catch (err) {
      setState(() => _testResult = '连接失败：$err');
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('GitHub 设置'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: '访问令牌（需要仓库权限）',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _repoController,
                decoration: const InputDecoration(
                  labelText: '仓库（用户名/仓库名）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: '分支（默认 main）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _registryPathController,
                decoration: const InputDecoration(
                  labelText: 'registry.json 路径',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _assetRegistryPathController,
                decoration: const InputDecoration(
                  labelText: 'app/assets/registry.json 路径（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _uploadBasePathController,
                decoration: const InputDecoration(
                  labelText: '上传目录（仓库内）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '注意：访问令牌会明文保存在本机设置文件中。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: const Icon(Icons.network_check),
                    label: const Text('测试连接'),
                  ),
                  if (_testing) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _testResult!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFB94A48))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('保存')),
      ],
    );
  }
}

class AddEnterpriseDialog extends StatefulWidget {
  const AddEnterpriseDialog({super.key, required this.existing});

  final List<Enterprise> existing;

  @override
  State<AddEnterpriseDialog> createState() => _AddEnterpriseDialogState();
}

class _AddEnterpriseDialogState extends State<AddEnterpriseDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _localOnly = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) {
      setState(() => _error = '企业 ID 和名称不能为空。');
      return;
    }
    if (widget.existing.any((e) => e.id == id)) {
      setState(() => _error = '该企业 ID 已存在。');
      return;
    }
    Navigator.of(context).pop(
      Enterprise(id: id, name: name, tools: [], localOnly: _localOnly),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新增企业'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '企业 ID（小写、短横线）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '企业名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _localOnly,
              onChanged: (value) =>
                  setState(() => _localOnly = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('仅本地保存（不写回 GitHub）'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFB94A48))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class AddToolDialog extends StatefulWidget {
  const AddToolDialog({
    super.key,
    required this.enterprises,
    required this.selectedEnterpriseId,
    required this.settings,
  });

  final List<Enterprise> enterprises;
  final String? selectedEnterpriseId;
  final GitHubSettings? settings;

  @override
  State<AddToolDialog> createState() => _AddToolDialogState();
}

class _AddToolDialogState extends State<AddToolDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _versionController = TextEditingController(text: '0.1.0');
  final _descController = TextEditingController();
  final _macUrlController = TextEditingController();
  final _winUrlController = TextEditingController();
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  final _workingDirController = TextEditingController();
  final _localPathController = TextEditingController();
  String? _macLocalPath;
  String? _winLocalPath;
  String _type = 'download';
  bool _localOnly = false;
  String? _enterpriseId;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enterpriseId = widget.selectedEnterpriseId ??
        (widget.enterprises.isNotEmpty ? widget.enterprises.first.id : null);
    final initialEnterprise = widget.enterprises.firstWhere(
      (e) => e.id == _enterpriseId,
      orElse: () => Enterprise.empty(),
    );
    _localOnly = initialEnterprise.localOnly;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _versionController.dispose();
    _descController.dispose();
    _macUrlController.dispose();
    _winUrlController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _workingDirController.dispose();
    _localPathController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFile(String platform) async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;
    _setLocalPath(platform, path);
  }

  Future<void> _pickLocalFolder(String platform) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    _setLocalPath(platform, path);
  }

  void _setLocalPath(String platform, String path) {
    setState(() {
      if (platform == 'macos') {
        _macLocalPath = path;
        _macUrlController.text = '';
      } else if (platform == 'windows') {
        _winLocalPath = path;
        _winUrlController.text = '';
      } else {
        _localPathController.text = path;
        _storeBookmark(path);
      }
      if (_type == 'download') {
        _localOnly = false;
      }
    });
  }

  Future<void> _storeBookmark(String path) async {
    if (!Platform.isMacOS) return;
    try {
      final bookmark = await BookmarkService.createBookmark(path);
      if (bookmark != null && bookmark.isNotEmpty) {
        await LocalStore.saveBookmark(path, bookmark);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_error != null) {
      setState(() => _error = null);
    }
    final enterpriseId = _enterpriseId;
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final version = _versionController.text.trim();
    if (enterpriseId == null || enterpriseId.isEmpty) {
      setState(() => _error = '请选择企业。');
      return;
    }
    if (id.isEmpty || name.isEmpty || version.isEmpty) {
      setState(() => _error = '工具 ID、名称、版本不能为空。');
      return;
    }
    final existingEnterprise =
        widget.enterprises.where((e) => e.id == enterpriseId).toList();
    if (existingEnterprise.isNotEmpty &&
        existingEnterprise.first.tools.any((t) => t.id == id)) {
      setState(() => _error = '该企业下已存在相同工具 ID。');
      return;
    }
    final desc = _descController.text.trim();
    if (_type == 'cli') {
      final command = _commandController.text.trim();
      if (command.isEmpty) {
        setState(() => _error = 'CLI 工具必须填写命令。');
        return;
      }
      final args = _parseArgs(_argsController.text);
      final tool = Tool(
        enterpriseId: enterpriseId,
        id: id,
        name: name,
        version: version,
        description: desc,
        platforms: const {},
        type: 'cli',
        command: command,
        args: args,
        workingDir: _workingDirController.text.trim(),
        localOnly: _localOnly,
      );
      Navigator.of(context).pop(tool);
      return;
    }
    if (_type == 'local') {
      final localPath = _localPathController.text.trim();
      if (localPath.isEmpty) {
        setState(() => _error = '本地路径不能为空。');
        return;
      }
      final tool = Tool(
        enterpriseId: enterpriseId,
        id: id,
        name: name,
        version: version,
        description: desc,
        platforms: const {},
        type: 'local',
        localPath: localPath,
        localOnly: _localOnly,
      );
      Navigator.of(context).pop(tool);
      return;
    }

    final hasLocalUpload = _macLocalPath != null || _winLocalPath != null;
    if (hasLocalUpload) {
      final settings = widget.settings;
      if (settings == null || !settings.isValid) {
        setState(() => _error = '请先在“设置”中配置 GitHub 权限后再上传。');
        return;
      }
      setState(() => _saving = true);
      try {
        final platforms = <String, ToolPlatform>{};
        var macUrl = _macUrlController.text.trim();
        var winUrl = _winUrlController.text.trim();
        if (_macLocalPath != null) {
          final upload = await GitHubAssetUploader.uploadToolPackage(
            settings: settings,
            enterpriseId: enterpriseId,
            toolId: id,
            version: version,
            platform: 'macos',
            sourcePath: _macLocalPath!,
          );
          macUrl = upload.url;
          platforms['macos'] = ToolPlatform(asset: upload.asset, url: upload.url);
        } else if (macUrl.isNotEmpty) {
          platforms['macos'] = ToolPlatform(
            asset: _assetFromUrl(macUrl, enterpriseId, id, version, 'macos'),
            url: macUrl,
          );
        }
        if (_winLocalPath != null) {
          final upload = await GitHubAssetUploader.uploadToolPackage(
            settings: settings,
            enterpriseId: enterpriseId,
            toolId: id,
            version: version,
            platform: 'windows',
            sourcePath: _winLocalPath!,
          );
          winUrl = upload.url;
          platforms['windows'] = ToolPlatform(asset: upload.asset, url: upload.url);
        } else if (winUrl.isNotEmpty) {
          platforms['windows'] = ToolPlatform(
            asset: _assetFromUrl(winUrl, enterpriseId, id, version, 'windows'),
            url: winUrl,
          );
        }
        if (platforms.isEmpty) {
          setState(() => _error = '至少提供一个下载地址或上传文件。');
          return;
        }
        final tool = Tool(
          enterpriseId: enterpriseId,
          id: id,
          name: name,
          version: version,
          description: desc,
          platforms: platforms,
          type: 'download',
          localOnly: false,
        );
        Navigator.of(context).pop(tool);
      } catch (err) {
        setState(() => _error = '上传失败：$err');
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
      return;
    }

    final macUrl = _macUrlController.text.trim();
    final winUrl = _winUrlController.text.trim();
    if (macUrl.isEmpty && winUrl.isEmpty) {
      setState(() => _error = '至少提供一个下载地址或上传文件。');
      return;
    }
    final platforms = <String, ToolPlatform>{};
    if (macUrl.isNotEmpty) {
      platforms['macos'] = ToolPlatform(
        asset: _assetFromUrl(macUrl, enterpriseId, id, version, 'macos'),
        url: macUrl,
      );
    }
    if (winUrl.isNotEmpty) {
      platforms['windows'] = ToolPlatform(
        asset: _assetFromUrl(winUrl, enterpriseId, id, version, 'windows'),
        url: winUrl,
      );
    }
    final tool = Tool(
      enterpriseId: enterpriseId,
      id: id,
      name: name,
      version: version,
      description: desc,
      platforms: platforms,
      type: 'download',
      localOnly: _localOnly,
    );
    Navigator.of(context).pop(tool);
  }

  @override
  Widget build(BuildContext context) {
    final disableLocalOnly =
        _type == 'download' && (_macLocalPath != null || _winLocalPath != null);
    return AlertDialog(
      title: const Text('新增工具'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _enterpriseId,
                items: widget.enterprises
                    .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _enterpriseId = value;
                    final enterprise = widget.enterprises.firstWhere(
                      (e) => e.id == value,
                      orElse: () => Enterprise.empty(),
                    );
                    _localOnly = enterprise.localOnly;
                  });
                },
                decoration: const InputDecoration(
                  labelText: '所属企业',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '工具 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '工具名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _versionController,
                decoration: const InputDecoration(
                  labelText: '版本',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'download', child: Text('下载工具')),
                  DropdownMenuItem(value: 'cli', child: Text('命令行工具')),
                  DropdownMenuItem(value: 'local', child: Text('本地工具')),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? 'download'),
                decoration: const InputDecoration(
                  labelText: '工具类型',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_type == 'download') ...[
                TextField(
                  controller: _macUrlController,
                  decoration: const InputDecoration(
                    labelText: 'macOS 下载地址',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('macos'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择 macOS 文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFolder('macos'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择 macOS 文件夹'),
                    ),
                    if (_macLocalPath != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '清除',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _macLocalPath = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                if (_macLocalPath != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已选择：$_macLocalPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _winUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Windows 下载地址',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('windows'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择 Windows 文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed:
                          _saving ? null : () => _pickLocalFolder('windows'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择 Windows 文件夹'),
                    ),
                    if (_winLocalPath != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '清除',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _winLocalPath = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                if (_winLocalPath != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已选择：$_winLocalPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
                if (_macLocalPath != null || _winLocalPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '将自动上传到 GitHub，供所有人下载。',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ],
              if (_type == 'cli') ...[
                TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: '命令',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _argsController,
                  decoration: const InputDecoration(
                    labelText: '参数（空格分隔）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workingDirController,
                  decoration: const InputDecoration(
                    labelText: '工作目录（可空）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_type == 'local') ...[
                TextField(
                  controller: _localPathController,
                  decoration: const InputDecoration(
                    labelText: '本地文件/文件夹路径',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('local'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFolder('local'),
                      icon: const Icon(Icons.folder),
                      label: const Text('选择文件夹'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '提示：本地路径只对当前电脑有效。',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _localOnly,
                onChanged: disableLocalOnly
                    ? null
                    : (value) => setState(() => _localOnly = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('仅本地保存（不写回 GitHub）'),
                subtitle: const Text('本地保存不需要 GitHub 权限'),
              ),
              if (_saving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 4),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFB94A48))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class EditEnterpriseDialog extends StatefulWidget {
  const EditEnterpriseDialog({super.key, required this.enterprise});

  final Enterprise enterprise;

  @override
  State<EditEnterpriseDialog> createState() => _EditEnterpriseDialogState();
}

class _EditEnterpriseDialogState extends State<EditEnterpriseDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.enterprise.id);
    _nameController = TextEditingController(text: widget.enterprise.name);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '企业名称不能为空。');
      return;
    }
    Navigator.of(context).pop(
      Enterprise(
        id: widget.enterprise.id,
        name: name,
        tools: widget.enterprise.tools,
        localOnly: widget.enterprise.localOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑企业'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _idController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '企业 ID（不可修改）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '企业名称',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.enterprise.localOnly) ...[
              const SizedBox(height: 8),
              Text(
                '提示：该企业为本地保存，仅当前电脑可见。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFB94A48))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class EditToolDialog extends StatefulWidget {
  const EditToolDialog({
    super.key,
    required this.tool,
    required this.enterprises,
    required this.settings,
  });

  final Tool tool;
  final List<Enterprise> enterprises;
  final GitHubSettings? settings;

  @override
  State<EditToolDialog> createState() => _EditToolDialogState();
}

class _EditToolDialogState extends State<EditToolDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _versionController;
  late final TextEditingController _descController;
  late final TextEditingController _macUrlController;
  late final TextEditingController _winUrlController;
  late final TextEditingController _commandController;
  late final TextEditingController _argsController;
  late final TextEditingController _workingDirController;
  late final TextEditingController _localPathController;
  late String _type;
  String? _error;
  String? _macLocalPath;
  String? _winLocalPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.tool.id);
    _nameController = TextEditingController(text: widget.tool.name);
    _versionController = TextEditingController(text: widget.tool.version);
    _descController = TextEditingController(text: widget.tool.description);
    _type = widget.tool.type.isEmpty ? 'download' : widget.tool.type;
    _macUrlController = TextEditingController(
      text: widget.tool.platforms['macos']?.url ?? '',
    );
    _winUrlController = TextEditingController(
      text: widget.tool.platforms['windows']?.url ?? '',
    );
    _commandController = TextEditingController(text: widget.tool.command ?? '');
    _argsController = TextEditingController(text: widget.tool.args.join(' '));
    _workingDirController =
        TextEditingController(text: widget.tool.workingDir ?? '');
    _localPathController =
        TextEditingController(text: widget.tool.localPath ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _versionController.dispose();
    _descController.dispose();
    _macUrlController.dispose();
    _winUrlController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    _workingDirController.dispose();
    _localPathController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFile(String platform) async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;
    _setLocalPath(platform, path);
  }

  Future<void> _pickLocalFolder(String platform) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    _setLocalPath(platform, path);
  }

  void _setLocalPath(String platform, String path) {
    setState(() {
      if (platform == 'macos') {
        _macLocalPath = path;
        _macUrlController.text = '';
      } else if (platform == 'windows') {
        _winLocalPath = path;
        _winUrlController.text = '';
      } else {
        _localPathController.text = path;
        _storeBookmark(path);
      }
    });
  }

  Future<void> _storeBookmark(String path) async {
    if (!Platform.isMacOS) return;
    try {
      final bookmark = await BookmarkService.createBookmark(path);
      if (bookmark != null && bookmark.isNotEmpty) {
        await LocalStore.saveBookmark(path, bookmark);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_error != null) {
      setState(() => _error = null);
    }
    final name = _nameController.text.trim();
    final version = _versionController.text.trim();
    if (name.isEmpty || version.isEmpty) {
      setState(() => _error = '工具名称和版本不能为空。');
      return;
    }
    final desc = _descController.text.trim();
    if (_type == 'cli') {
      final command = _commandController.text.trim();
      if (command.isEmpty) {
        setState(() => _error = '命令不能为空。');
        return;
      }
      final args = _parseArgs(_argsController.text);
      Navigator.of(context).pop(
        Tool(
          enterpriseId: widget.tool.enterpriseId,
          id: widget.tool.id,
          name: name,
          version: version,
          description: desc,
          platforms: const {},
          type: 'cli',
          command: command,
          args: args,
          workingDir: _workingDirController.text.trim(),
          localOnly: widget.tool.localOnly,
        ),
      );
      return;
    }
    if (_type == 'local') {
      final localPath = _localPathController.text.trim();
      if (localPath.isEmpty) {
        setState(() => _error = '本地路径不能为空。');
        return;
      }
      Navigator.of(context).pop(
        Tool(
          enterpriseId: widget.tool.enterpriseId,
          id: widget.tool.id,
          name: name,
          version: version,
          description: desc,
          platforms: const {},
          type: 'local',
          localPath: localPath,
          localOnly: widget.tool.localOnly,
        ),
      );
      return;
    }

    final hasLocalUpload = _macLocalPath != null || _winLocalPath != null;
    if (hasLocalUpload) {
      final settings = widget.settings;
      if (settings == null || !settings.isValid) {
        setState(() => _error = '请先在“设置”中配置 GitHub 权限后再上传。');
        return;
      }
      setState(() => _saving = true);
      try {
        final platforms = <String, ToolPlatform>{};
        var macUrl = _macUrlController.text.trim();
        var winUrl = _winUrlController.text.trim();
        if (_macLocalPath != null) {
          final upload = await GitHubAssetUploader.uploadToolPackage(
            settings: settings,
            enterpriseId: widget.tool.enterpriseId,
            toolId: widget.tool.id,
            version: version,
            platform: 'macos',
            sourcePath: _macLocalPath!,
          );
          macUrl = upload.url;
          platforms['macos'] = ToolPlatform(asset: upload.asset, url: upload.url);
        } else if (macUrl.isNotEmpty) {
          platforms['macos'] = ToolPlatform(
            asset: _assetFromUrl(macUrl, widget.tool.enterpriseId, widget.tool.id,
                version, 'macos'),
            url: macUrl,
          );
        }
        if (_winLocalPath != null) {
          final upload = await GitHubAssetUploader.uploadToolPackage(
            settings: settings,
            enterpriseId: widget.tool.enterpriseId,
            toolId: widget.tool.id,
            version: version,
            platform: 'windows',
            sourcePath: _winLocalPath!,
          );
          winUrl = upload.url;
          platforms['windows'] =
              ToolPlatform(asset: upload.asset, url: upload.url);
        } else if (winUrl.isNotEmpty) {
          platforms['windows'] = ToolPlatform(
            asset: _assetFromUrl(winUrl, widget.tool.enterpriseId, widget.tool.id,
                version, 'windows'),
            url: winUrl,
          );
        }
        if (platforms.isEmpty) {
          setState(() => _error = '至少提供一个下载地址或上传文件。');
          return;
        }
        Navigator.of(context).pop(
          Tool(
            enterpriseId: widget.tool.enterpriseId,
            id: widget.tool.id,
            name: name,
            version: version,
            description: desc,
            platforms: platforms,
            type: 'download',
            localOnly: widget.tool.localOnly,
          ),
        );
      } catch (err) {
        setState(() => _error = '上传失败：$err');
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
      return;
    }

    final macUrl = _macUrlController.text.trim();
    final winUrl = _winUrlController.text.trim();
    if (macUrl.isEmpty && winUrl.isEmpty) {
      setState(() => _error = '至少提供一个下载地址或上传文件。');
      return;
    }
    final platforms = <String, ToolPlatform>{};
    if (macUrl.isNotEmpty) {
      platforms['macos'] = ToolPlatform(
        asset: _assetFromUrl(macUrl, widget.tool.enterpriseId, widget.tool.id,
            version, 'macos'),
        url: macUrl,
      );
    }
    if (winUrl.isNotEmpty) {
      platforms['windows'] = ToolPlatform(
        asset: _assetFromUrl(winUrl, widget.tool.enterpriseId, widget.tool.id,
            version, 'windows'),
        url: winUrl,
      );
    }
    Navigator.of(context).pop(
      Tool(
        enterpriseId: widget.tool.enterpriseId,
        id: widget.tool.id,
        name: name,
        version: version,
        description: desc,
        platforms: platforms,
        type: 'download',
        localOnly: widget.tool.localOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑工具'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _idController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '工具 ID（不可修改）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '工具名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _versionController,
                decoration: const InputDecoration(
                  labelText: '版本',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'download', child: Text('下载工具')),
                  DropdownMenuItem(value: 'cli', child: Text('命令行工具')),
                  DropdownMenuItem(value: 'local', child: Text('本地工具')),
                ],
                onChanged: (value) =>
                    setState(() => _type = value ?? 'download'),
                decoration: const InputDecoration(
                  labelText: '工具类型',
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.tool.localOnly) ...[
                const SizedBox(height: 8),
                Text(
                  '提示：该工具为本地保存，仅当前电脑可见。',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 12),
              if (_type == 'download') ...[
                TextField(
                  controller: _macUrlController,
                  decoration: const InputDecoration(
                    labelText: 'macOS 下载地址',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('macos'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择 macOS 文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFolder('macos'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择 macOS 文件夹'),
                    ),
                    if (_macLocalPath != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '清除',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _macLocalPath = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                if (_macLocalPath != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已选择：$_macLocalPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _winUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Windows 下载地址',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('windows'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('选择 Windows 文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed:
                          _saving ? null : () => _pickLocalFolder('windows'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择 Windows 文件夹'),
                    ),
                    if (_winLocalPath != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '清除',
                        onPressed: _saving
                            ? null
                            : () => setState(() => _winLocalPath = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                if (_winLocalPath != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '已选择：$_winLocalPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
                if (_macLocalPath != null || _winLocalPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '将自动上传到 GitHub，供所有人下载。',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ],
              if (_type == 'cli') ...[
                TextField(
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: '命令',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _argsController,
                  decoration: const InputDecoration(
                    labelText: '参数（空格分隔）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workingDirController,
                  decoration: const InputDecoration(
                    labelText: '工作目录（可空）',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_type == 'local') ...[
                TextField(
                  controller: _localPathController,
                  decoration: const InputDecoration(
                    labelText: '本地文件/文件夹路径',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFile('local'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pickLocalFolder('local'),
                      icon: const Icon(Icons.folder),
                      label: const Text('选择文件夹'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '提示：本地路径只对当前电脑有效。',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
              ],
              if (_saving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 4),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFB94A48))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('保存')),
      ],
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('确认')),
      ],
    );
  }
}

class CliToolDialog extends StatefulWidget {
  const CliToolDialog({
    super.key,
    required this.title,
    required this.command,
    required this.args,
    this.workingDir,
  });

  final String title;
  final String command;
  final List<String> args;
  final String? workingDir;

  @override
  State<CliToolDialog> createState() => _CliToolDialogState();
}

class _CliToolDialogState extends State<CliToolDialog> {
  final List<String> _lines = [];
  Process? _process;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _process?.kill(ProcessSignal.sigterm);
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;
    setState(() {
      _running = true;
      _lines.clear();
    });
    try {
      final process = await Process.start(
        widget.command,
        widget.args,
        runInShell: true,
        workingDirectory: _normalizeWorkingDir(widget.workingDir),
      );
      _process = process;
      _appendLine('正在运行：${widget.command} ${widget.args.join(' ')}');
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_appendLine);
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLine('[错误] $line'));
      final code = await process.exitCode;
      _appendLine('进程退出，退出码：$code');
    } catch (err) {
      _appendLine('启动失败：$err');
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  void _appendLine(String line) {
    if (!mounted) return;
    setState(() {
      _lines.add(line);
      if (_lines.length > 500) {
        _lines.removeRange(0, _lines.length - 500);
      }
    });
  }

  void _stop() {
    _process?.kill(ProcessSignal.sigterm);
      _appendLine('进程已终止。');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: 560,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1B1A17),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _running ? null : _start,
                    child: const Text('重新运行'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _running ? _stop : null,
                    child: const Text('停止'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFF0E1114),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: SelectableText(
                    _lines.join('\n'),
                    style: const TextStyle(
                      color: Color(0xFFDDE2E6),
                      fontFamily: 'Menlo',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistryService {
  static Registry? _cache;

  static Future<Registry> loadRegistry({GitHubSettings? settings}) async {
    if (_cache != null) {
      return _cache!;
    }
    String? content;
    if (settings != null && settings.isValid) {
      try {
        content = await _fetchFromGitHub(settings);
      } catch (_) {
        content = null;
      }
    }
    if (content == null || content.isEmpty) {
      try {
        content = await _fetchUrl(registryUrl);
      } catch (_) {
        content = null;
      }
    }

    if (content == null || content.isEmpty) {
      content = await rootBundle.loadString('assets/registry.json');
    }

    final jsonData = jsonDecode(content) as Map<String, dynamic>;
    final remote = Registry.fromJson(jsonData);
    final local = await LocalStore.loadLocalRegistry();
    _cache = Registry.merge(remote, local);
    return _cache!;
  }

  static void clearCache() {
    _cache = null;
  }

  static Future<String?> _fetchUrl(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        return null;
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  static Future<String?> _fetchFromGitHub(GitHubSettings settings) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/${settings.repo}/contents/${settings.registryPath}?ref=${settings.branch}',
    );
    final headers = {
      'Authorization': 'Bearer ${settings.token}',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'enterprise-tools-app',
    };
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      return null;
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final content = data['content'] as String?;
    if (content == null || content.isEmpty) return null;
    final normalized = content.replaceAll('\n', '');
    final bytes = base64Decode(normalized);
    return utf8.decode(bytes);
  }
}

class GitHubSettings {
  GitHubSettings({
    required this.token,
    required this.repo,
    required this.branch,
    required this.registryPath,
    required this.assetRegistryPath,
    required this.uploadBasePath,
  });

  final String token;
  final String repo;
  final String branch;
  final String registryPath;
  final String assetRegistryPath;
  final String uploadBasePath;

  bool get isValid => token.isNotEmpty && repo.contains('/');

  Map<String, dynamic> toJson() => {
        'token': token,
        'repo': repo,
        'branch': branch,
        'registryPath': registryPath,
        'assetRegistryPath': assetRegistryPath,
        'uploadBasePath': uploadBasePath,
      };

  factory GitHubSettings.fromJson(Map<String, dynamic> json) {
    return GitHubSettings(
      token: json['token'] as String? ?? '',
      repo: json['repo'] as String? ?? '',
      branch: json['branch'] as String? ?? 'main',
      registryPath: json['registryPath'] as String? ?? 'registry.json',
      assetRegistryPath: json['assetRegistryPath'] as String? ?? 'app/assets/registry.json',
      uploadBasePath: json['uploadBasePath'] as String? ?? 'tools',
    );
  }

  static GitHubSettings defaultSettings() {
    return GitHubSettings(
      token: '',
      repo: 'qgbd2xvc9p-art/enterprise-tools',
      branch: 'main',
      registryPath: 'registry.json',
      assetRegistryPath: 'app/assets/registry.json',
      uploadBasePath: 'tools',
    );
  }
}

class GitHubRegistryWriter {
  static Future<void> updateRegistry({
    required GitHubSettings settings,
    required Registry registry,
  }) async {
    final jsonText = jsonEncode(registry.toJson());
    await _updateFile(
      settings: settings,
      path: settings.registryPath,
      content: jsonText,
      message: '更新 registry.json',
    );
    final assetPath = settings.assetRegistryPath.trim();
    if (assetPath.isNotEmpty) {
      await _updateFile(
        settings: settings,
        path: assetPath,
        content: jsonText,
        message: '同步 app/assets/registry.json',
      );
    }
  }

  static Future<void> _updateFile({
    required GitHubSettings settings,
    required String path,
    required String content,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/${settings.repo}/contents/$path?ref=${settings.branch}',
    );
    final headers = {
      'Authorization': 'Bearer ${settings.token}',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'enterprise-tools-app',
    };

    String? sha;
    final getResp = await http.get(uri, headers: headers);
    if (getResp.statusCode == 200) {
      final data = jsonDecode(getResp.body) as Map<String, dynamic>;
      sha = data['sha'] as String?;
    } else if (getResp.statusCode != 404) {
      throw Exception('读取文件失败：${getResp.statusCode}');
    }

    final body = {
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'branch': settings.branch,
    };
    if (sha != null) {
      body['sha'] = sha;
    }
    final putResp = await http.put(uri, headers: headers, body: jsonEncode(body));
    if (putResp.statusCode < 200 || putResp.statusCode >= 300) {
      throw Exception('写入失败：${putResp.statusCode} ${putResp.body}');
    }
  }
}

class UploadResult {
  UploadResult({required this.url, required this.asset});

  final String url;
  final String asset;
}

class GitHubAssetUploader {
  static Future<UploadResult> uploadToolPackage({
    required GitHubSettings settings,
    required String enterpriseId,
    required String toolId,
    required String version,
    required String platform,
    required String sourcePath,
  }) async {
    final assetName = _buildAssetName(
      enterpriseId: enterpriseId,
      toolId: toolId,
      version: version,
      platform: platform,
    );
    final prepared = await _prepareZip(sourcePath, assetName);
    try {
      final bytes = await prepared.file.readAsBytes();
      const maxBytes = 100 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        throw Exception('文件过大，超过 100MB（GitHub 内容接口限制）');
      }
      final repo = _splitRepo(settings.repo);
      final basePath = settings.uploadBasePath.trim().isEmpty
          ? 'tools'
          : settings.uploadBasePath.trim();
      final path = '$basePath/$enterpriseId/$toolId/$version/$assetName';
      final sha = await _fetchContentSha(
        settings: settings,
        owner: repo.owner,
        repo: repo.name,
        path: path,
      );
      await _uploadContent(
        settings: settings,
        owner: repo.owner,
        repo: repo.name,
        path: path,
        contentBytes: bytes,
        message: '上传工具包 $enterpriseId/$toolId $version $platform',
        sha: sha,
      );
      final url =
          'https://raw.githubusercontent.com/${repo.owner}/${repo.name}/${settings.branch}/$path';
      return UploadResult(url: url, asset: assetName);
    } finally {
      if (prepared.deleteAfter) {
        try {
          await prepared.file.delete();
          await prepared.file.parent.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  static String _buildAssetName({
    required String enterpriseId,
    required String toolId,
    required String version,
    required String platform,
  }) {
    return '$enterpriseId-$toolId-$version-$platform.zip';
  }

  static Future<String?> _fetchContentSha({
    required GitHubSettings settings,
    required String owner,
    required String repo,
    required String path,
  }) async {
    final base = 'https://api.github.com/repos/$owner/$repo';
    final headers = _buildHeaders(settings);
    final uri = Uri.parse('$base/contents/$path?ref=${settings.branch}');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['sha'] as String?;
    }
    if (resp.statusCode == 404) return null;
    throw Exception('读取文件失败：${resp.statusCode}');
  }

  static Future<void> _uploadContent({
    required GitHubSettings settings,
    required String owner,
    required String repo,
    required String path,
    required List<int> contentBytes,
    required String message,
    String? sha,
  }) async {
    final base = 'https://api.github.com/repos/$owner/$repo';
    final uri = Uri.parse('$base/contents/$path');
    final headers = _buildHeaders(settings);
    final body = <String, dynamic>{
      'message': message,
      'content': base64Encode(contentBytes),
      'branch': settings.branch,
    };
    if (sha != null) {
      body['sha'] = sha;
    }
    final resp =
        await http.put(uri, headers: headers, body: jsonEncode(body));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('上传失败：${resp.statusCode} ${resp.body}');
    }
  }

  static Map<String, String> _buildHeaders(GitHubSettings settings) {
    return {
      'Authorization': 'Bearer ${settings.token}',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'enterprise-tools-app',
    };
  }

  static _RepoInfo _splitRepo(String repo) {
    final parts = repo.split('/');
    if (parts.length != 2) {
      throw Exception('仓库格式错误，应为 owner/repo');
    }
    return _RepoInfo(owner: parts[0], name: parts[1]);
  }

  static Future<_PreparedFile> _prepareZip(
    String sourcePath,
    String assetName,
  ) async {
    final type = FileSystemEntity.typeSync(sourcePath);
    if (type == FileSystemEntityType.notFound) {
      throw Exception('本地路径不存在');
    }
    final tempDir = await Directory.systemTemp.createTemp('enterprise-tools');
    final tempFile = File('${tempDir.path}/$assetName');
    if (type == FileSystemEntityType.file) {
      final source = File(sourcePath);
      if (source.path.toLowerCase().endsWith('.zip')) {
        if (_basename(source.path) == assetName) {
          return _PreparedFile(file: source, deleteAfter: false);
        }
        await source.copy(tempFile.path);
        return _PreparedFile(file: tempFile, deleteAfter: true);
      }
      final archive = Archive();
      final bytes = await source.readAsBytes();
      archive.addFile(ArchiveFile(_basename(source.path), bytes.length, bytes));
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('压缩失败');
      }
      await tempFile.writeAsBytes(zipData, flush: true);
      return _PreparedFile(file: tempFile, deleteAfter: true);
    }
    if (type == FileSystemEntityType.directory) {
      final archive = Archive();
      final dir = Directory(sourcePath);
      final basePath = dir.path;
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          final relative = _relativePath(basePath, entity.path);
          archive.addFile(ArchiveFile(relative, bytes.length, bytes));
        }
      }
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('压缩失败');
      }
      await tempFile.writeAsBytes(zipData, flush: true);
      return _PreparedFile(file: tempFile, deleteAfter: true);
    }
    throw Exception('不支持的路径类型');
  }
}

class _PreparedFile {
  _PreparedFile({required this.file, required this.deleteAfter});

  final File file;
  final bool deleteAfter;
}

class _RepoInfo {
  _RepoInfo({required this.owner, required this.name});

  final String owner;
  final String name;
}

class BookmarkService {
  static const MethodChannel _channel = MethodChannel('enterprise_tools/bookmark');

  static Future<String?> createBookmark(String path) async {
    if (!Platform.isMacOS) return null;
    final result =
        await _channel.invokeMethod<String>('createBookmark', path);
    return result;
  }

  static Future<bool> startAccess(String bookmark) async {
    if (!Platform.isMacOS) return true;
    final result =
        await _channel.invokeMethod<bool>('startAccess', bookmark);
    return result ?? false;
  }

  static Future<void> stopAccess(String bookmark) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod('stopAccess', bookmark);
  }

  static Future<void> copyItem(String source, String destination) async {
    if (!Platform.isMacOS) return;
    await _channel.invokeMethod('copyItem', {
      'source': source,
      'destination': destination,
    });
  }
}

class AuthService {
  static List<User>? _cache;

  static Future<User?> authenticate(String username, String password) async {
    final users = await _loadUsers();
    for (final user in users) {
      if (user.username == username && user.password == password) {
        return user;
      }
    }
    return null;
  }

  static Future<List<User>> _loadUsers() async {
    if (_cache != null) {
      return _cache!;
    }
    final content = await rootBundle.loadString('assets/users.json');
    final jsonData = jsonDecode(content) as Map<String, dynamic>;
    final users = (jsonData['users'] as List<dynamic>)
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
    _cache = users;
    return users;
  }
}

class DownloadService {
  static Future<InstalledEntry> downloadTool({
    required Tool tool,
    required ToolPlatform platform,
    required ValueChanged<double> onProgress,
  }) async {
    final downloadDir = await LocalStore.downloadDirectory(
      enterpriseId: tool.enterpriseId,
      toolId: tool.id,
    );
    await downloadDir.create(recursive: true);

    final filePath = '${downloadDir.path}/${platform.asset}';
    final file = File(filePath);

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(platform.url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final total = response.contentLength;
      int received = 0;
      final completer = Completer<void>();
      final sink = file.openWrite();
      response.listen(
        (chunk) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) {
            onProgress(received / total);
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          onProgress(1);
          completer.complete();
        },
        onError: (err) async {
          await sink.flush();
          await sink.close();
          completer.completeError(err);
        },
        cancelOnError: true,
      );
      await completer.future;
    } finally {
      client.close();
    }

    final updatedAt = DateTime.now().toIso8601String();
    return InstalledEntry(
      version: tool.version,
      path: file.path,
      updatedAt: updatedAt,
    );
  }
}

class LocalStore {
  static Future<GitHubSettings?> loadSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    final data = jsonDecode(content) as Map<String, dynamic>;
    return GitHubSettings.fromJson(data);
  }

  static Future<Registry> loadLocalRegistry() async {
    final file = await _localRegistryFile();
    if (!await file.exists()) {
      return Registry(enterprises: []);
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return Registry(enterprises: []);
    }
    final data = jsonDecode(content) as Map<String, dynamic>;
    return Registry.fromJson(data, localOnly: true);
  }

  static Future<void> saveLocalRegistry(Registry registry) async {
    final file = await _localRegistryFile();
    await file.writeAsString(jsonEncode(registry.toJson()));
  }

  static Future<void> saveSettings(GitHubSettings settings) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(settings.toJson()));
  }

  static Future<Map<String, InstalledEntry>> loadInstalled() async {
    final file = await _installedFile();
    if (!await file.exists()) {
      return {};
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return {};
    }
    final data = jsonDecode(content) as Map<String, dynamic>;
    final map = <String, InstalledEntry>{};
    data.forEach((key, value) {
      map[key] = InstalledEntry.fromJson(value as Map<String, dynamic>);
    });
    return map;
  }

  static Future<String?> loadBookmark(String path) async {
    final file = await _bookmarkFile();
    if (!await file.exists()) {
      return null;
    }
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    final data = jsonDecode(content) as Map<String, dynamic>;
    final value = data[path] as String?;
    return value;
  }

  static Future<void> saveBookmark(String path, String bookmark) async {
    final file = await _bookmarkFile();
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        data = jsonDecode(content) as Map<String, dynamic>;
      }
    }
    data[path] = bookmark;
    await file.writeAsString(jsonEncode(data));
  }

  static Future<void> saveInstalled(
    Map<String, InstalledEntry> installed,
  ) async {
    final file = await _installedFile();
    final data = installed.map((key, value) => MapEntry(key, value.toJson()));
    await file.writeAsString(jsonEncode(data));
  }

  static Future<Directory> downloadDirectory({
    required String enterpriseId,
    required String toolId,
  }) async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/downloads/$enterpriseId/$toolId');
    return dir;
  }

  static Future<File> _installedFile() async {
    final base = await _baseDir();
    await base.create(recursive: true);
    return File('${base.path}/installed.json');
  }

  static Future<File> _settingsFile() async {
    final base = await _baseDir();
    await base.create(recursive: true);
    return File('${base.path}/settings.json');
  }

  static Future<File> _bookmarkFile() async {
    final base = await _baseDir();
    await base.create(recursive: true);
    return File('${base.path}/bookmarks.json');
  }

  static Future<File> _localRegistryFile() async {
    final base = await _baseDir();
    await base.create(recursive: true);
    return File('${base.path}/local_registry.json');
  }

  static Future<Directory> _baseDir() async {
    if (Platform.isWindows) {
      final env = Platform.environment['APPDATA'] ??
          Platform.environment['LOCALAPPDATA'];
      if (env != null && env.isNotEmpty) {
        return Directory('$env/EnterpriseTools');
      }
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      if (Platform.isMacOS) {
        return Directory('$home/Library/Application Support/EnterpriseTools');
      }
      return Directory('$home/.enterprise-tools');
    }
    return Directory.current;
  }
}

class User {
  User({
    required this.username,
    required this.password,
    required this.roles,
    required this.enterprises,
  });

  final String username;
  final String password;
  final List<String> roles;
  final List<String> enterprises;

  bool get isAdmin => roles.contains('admin');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      password: json['password'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
      enterprises: (json['enterprises'] as List<dynamic>).cast<String>(),
    );
  }
}

class Registry {
  Registry({required this.enterprises});

  final List<Enterprise> enterprises;

  factory Registry.fromJson(
    Map<String, dynamic> json, {
    bool localOnly = false,
  }) {
    final list = (json['enterprises'] as List<dynamic>)
        .map((item) =>
            Enterprise.fromJson(item as Map<String, dynamic>, localOnly: localOnly))
        .toList();
    return Registry(enterprises: list);
  }

  Registry copy() {
    return Registry(
      enterprises: enterprises.map((e) => e.copy()).toList(),
    );
  }

  Registry remoteOnly() {
    final filtered = <Enterprise>[];
    for (final enterprise in enterprises) {
      if (enterprise.localOnly) continue;
      final tools = enterprise.tools
          .where((tool) => !tool.localOnly)
          .map((tool) => tool.copy())
          .toList();
      filtered.add(
        Enterprise(
          id: enterprise.id,
          name: enterprise.name,
          tools: tools,
          localOnly: false,
        ),
      );
    }
    return Registry(enterprises: filtered);
  }

  static Registry merge(Registry remote, Registry local) {
    final merged = remote.copy();
    final lookup = <String, Enterprise>{
      for (final enterprise in merged.enterprises) enterprise.id: enterprise,
    };
    for (final localEnterprise in local.enterprises) {
      final existing = lookup[localEnterprise.id];
      if (existing == null) {
        final added = localEnterprise.copy();
        merged.enterprises.add(added);
        lookup[localEnterprise.id] = added;
        continue;
      }
      for (final localTool in localEnterprise.tools) {
        final exists = existing.tools.any((tool) => tool.id == localTool.id);
        if (!exists) {
          existing.tools.add(localTool.copy());
        }
      }
    }
    return merged;
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': DateTime.now().toIso8601String().split('T').first,
      'source': 'app',
      'enterprises': enterprises.map((e) => e.toJson()).toList(),
    };
  }
}

class Enterprise {
  Enterprise({
    required this.id,
    required this.name,
    required this.tools,
    this.localOnly = false,
  });

  final String id;
  final String name;
  final List<Tool> tools;
  final bool localOnly;

  factory Enterprise.fromJson(
    Map<String, dynamic> json, {
    bool localOnly = false,
  }) {
    final id = json['id'] as String;
    final tools = (json['tools'] as List<dynamic>)
        .map((item) => Tool.fromJson(
              id,
              item as Map<String, dynamic>,
              localOnly: localOnly,
            ))
        .toList();
    return Enterprise(
      id: id,
      name: json['name'] as String,
      tools: tools,
      localOnly: localOnly,
    );
  }

  factory Enterprise.empty() => Enterprise(id: '', name: '', tools: []);

  Enterprise copy() {
    return Enterprise(
      id: id,
      name: name,
      tools: tools.map((t) => t.copy()).toList(),
      localOnly: localOnly,
    );
  }

  Enterprise copyWith({
    String? id,
    String? name,
    List<Tool>? tools,
    bool? localOnly,
  }) {
    return Enterprise(
      id: id ?? this.id,
      name: name ?? this.name,
      tools: tools ?? this.tools.map((t) => t.copy()).toList(),
      localOnly: localOnly ?? this.localOnly,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tools': tools.map((t) => t.toJson()).toList(),
    };
  }
}

class Tool {
  Tool({
    required this.enterpriseId,
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.platforms,
    required this.type,
    this.url,
    this.command,
    this.args = const [],
    this.workingDir,
    this.localPath,
    this.localOnly = false,
  });

  final String enterpriseId;
  final String id;
  final String name;
  final String version;
  final String description;
  final Map<String, ToolPlatform> platforms;
  final String type;
  final String? url;
  final String? command;
  final List<String> args;
  final String? workingDir;
  final String? localPath;
  final bool localOnly;

  factory Tool.fromJson(
    String enterpriseId,
    Map<String, dynamic> json, {
    bool localOnly = false,
  }) {
    final platformsJson =
        (json['platforms'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final platforms = <String, ToolPlatform>{};
    platformsJson.forEach((key, value) {
      platforms[key] = ToolPlatform.fromJson(value as Map<String, dynamic>);
    });
    final type = (json['type'] as String?) ??
        (platforms.isNotEmpty ? 'download' : 'download');
    final rawArgs = json['args'];
    final args = <String>[];
    if (rawArgs is List) {
      args.addAll(rawArgs.map((item) => item.toString()));
    } else if (rawArgs is String && rawArgs.trim().isNotEmpty) {
      args.addAll(rawArgs.split(' '));
    }
    return Tool(
      enterpriseId: enterpriseId,
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String? ?? '',
      platforms: platforms,
      type: type,
      url: (json['url'] as String?) ?? (json['entrypoint'] as String?),
      command: json['command'] as String?,
      args: args,
      workingDir: _normalizeWorkingDir(json['workingDir'] as String?),
      localPath: _normalizeLocalPath(json['path'] as String?),
      localOnly: localOnly,
    );
  }

  Tool copy() {
    return Tool(
      enterpriseId: enterpriseId,
      id: id,
      name: name,
      version: version,
      description: description,
      platforms: platforms.map((key, value) => MapEntry(key, value.copy())),
      type: type,
      url: url,
      command: command,
      args: List<String>.from(args),
      workingDir: workingDir,
      localPath: localPath,
      localOnly: localOnly,
    );
  }

  Tool copyWith({
    String? enterpriseId,
    String? id,
    String? name,
    String? version,
    String? description,
    Map<String, ToolPlatform>? platforms,
    String? type,
    String? url,
    String? command,
    List<String>? args,
    String? workingDir,
    String? localPath,
    bool? localOnly,
  }) {
    return Tool(
      enterpriseId: enterpriseId ?? this.enterpriseId,
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      platforms: platforms ??
          this.platforms.map((key, value) => MapEntry(key, value.copy())),
      type: type ?? this.type,
      url: url ?? this.url,
      command: command ?? this.command,
      args: args ?? List<String>.from(this.args),
      workingDir: workingDir ?? this.workingDir,
      localPath: localPath ?? this.localPath,
      localOnly: localOnly ?? this.localOnly,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'version': version,
      'description': description,
    };
    if (type.isNotEmpty && type != 'download') {
      data['type'] = type;
    }
    if (platforms.isNotEmpty) {
      data['platforms'] = platforms.map((key, value) => MapEntry(key, value.toJson()));
    }
    if (type == 'cli') {
      data['type'] = 'cli';
      data['command'] = command ?? '';
      if (args.isNotEmpty) {
        data['args'] = args;
      }
      if (workingDir != null && workingDir!.trim().isNotEmpty) {
        data['workingDir'] = workingDir;
      }
    }
    if (type == 'local') {
      data['type'] = 'local';
      if (localPath != null && localPath!.trim().isNotEmpty) {
        data['path'] = localPath;
      }
    }
    return data;
  }
}

String? _normalizeWorkingDir(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _normalizeLocalPath(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _parseArgs(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return [];
  final args = <String>[];
  final buffer = StringBuffer();
  bool inQuotes = false;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (!inQuotes && char.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        args.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) {
    args.add(buffer.toString());
  }
  return args;
}

String _assetFromUrl(
  String url,
  String enterpriseId,
  String toolId,
  String version,
  String platform,
) {
  try {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
  } catch (_) {}
  return '$enterpriseId-$toolId-$version-$platform.zip';
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.isNotEmpty ? parts.last : path;
}

String _truncate(String value, {int max = 200}) {
  if (value.length <= max) return value;
  return '${value.substring(0, max)}...';
}

String _relativePath(String base, String path) {
  var baseNorm = base.replaceAll('\\', '/');
  var pathNorm = path.replaceAll('\\', '/');
  if (!baseNorm.endsWith('/')) {
    baseNorm = '$baseNorm/';
  }
  if (pathNorm.startsWith(baseNorm)) {
    return pathNorm.substring(baseNorm.length);
  }
  return _basename(pathNorm);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (entity is Directory) {
      final newDir = Directory(
        '${destination.path}/${_basename(entity.path)}',
      );
      await _copyDirectory(entity, newDir);
    } else if (entity is File) {
      final newFile = File(
        '${destination.path}/${_basename(entity.path)}',
      );
      await entity.copy(newFile.path);
    }
  }
}

Future<void> _copyFilePreserve(File source, String destinationPath) async {
  if (!Platform.isMacOS) {
    await source.copy(destinationPath);
    return;
  }
  await BookmarkService.copyItem(source.path, destinationPath);
}

Future<void> _copyDirectoryPreserve(
  Directory source,
  Directory destination,
) async {
  if (!Platform.isMacOS) {
    await _copyDirectory(source, destination);
    return;
  }
  await BookmarkService.copyItem(source.path, destination.path);
}

class ToolPlatform {
  ToolPlatform({required this.asset, required this.url});

  final String asset;
  final String url;

  factory ToolPlatform.fromJson(Map<String, dynamic> json) {
    return ToolPlatform(
      asset: json['asset'] as String,
      url: json['url'] as String,
    );
  }

  ToolPlatform copy() => ToolPlatform(asset: asset, url: url);

  Map<String, dynamic> toJson() {
    return {
      'asset': asset,
      'url': url,
    };
  }
}

class InstalledEntry {
  InstalledEntry({
    required this.version,
    required this.path,
    required this.updatedAt,
  });

  final String version;
  final String path;
  final String updatedAt;

  factory InstalledEntry.fromJson(Map<String, dynamic> json) {
    return InstalledEntry(
      version: json['version'] as String,
      path: json['path'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'path': path,
      'updatedAt': updatedAt,
    };
  }
}

int compareVersions(String a, String b) {
  final aParts = a.split('.').map(_parseVersionPart).toList();
  final bParts = b.split('.').map(_parseVersionPart).toList();
  final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < maxLen; i++) {
    final aVal = i < aParts.length ? aParts[i] : 0;
    final bVal = i < bParts.length ? bParts[i] : 0;
    if (aVal != bVal) {
      return aVal.compareTo(bVal);
    }
  }
  return 0;
}

int _parseVersionPart(String part) {
  return int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
