import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            _Tag(label: 'Desktop-first'),
            _Tag(label: 'Auto updates'),
            _Tag(label: 'Role-based access'),
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
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final registry = await RegistryService.loadRegistry();
      final installed = await LocalStore.loadInstalled();
      final visible = _filterEnterprises(registry.enterprises);
      setState(() {
        _registry = registry;
        _installed = installed;
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
      _showSnack('This tool is not available for this platform.');
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
                        ? const Center(child: Text('No registry found.'))
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
          Text(_error ?? 'Unknown error'),
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
                    child: Text(
                      enterprise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : Colors.black87,
                      ),
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
                TextButton(onPressed: widget.onLogout, child: const Text('Sign out'))
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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
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
                        ? 'CLI tool'
                        : 'Embedded tool',
              ),
              if (isDownloadTool && hasUpdate)
                const _InfoChip(label: '有新版本', accent: true),
              if (isDownloadTool && installed != null)
                _InfoChip(label: '保存位置：${installed.path}'),
              if (isCliTool && tool.command != null)
                _InfoChip(label: tool.command!),
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
              else
                FilledButton(
                  onPressed: () => _showSnack('此版本未启用 Web 工具。'),
                  child: const Text('不可用'),
                ),
              const SizedBox(width: 12),
              if (isDownloadTool && installed != null)
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
          .listen((line) => _appendLine('[err] $line'));
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
    _appendLine('Process terminated.');
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

  static Future<Registry> loadRegistry() async {
    if (_cache != null) {
      return _cache!;
    }
    String? content;
    try {
      content = await _fetchUrl(registryUrl);
    } catch (_) {
      content = null;
    }

    if (content == null || content.isEmpty) {
      content = await rootBundle.loadString('assets/registry.json');
    }

    final jsonData = jsonDecode(content) as Map<String, dynamic>;
    _cache = Registry.fromJson(jsonData);
    return _cache!;
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

  factory Registry.fromJson(Map<String, dynamic> json) {
    final list = (json['enterprises'] as List<dynamic>)
        .map((item) => Enterprise.fromJson(item as Map<String, dynamic>))
        .toList();
    return Registry(enterprises: list);
  }
}

class Enterprise {
  Enterprise({
    required this.id,
    required this.name,
    required this.tools,
  });

  final String id;
  final String name;
  final List<Tool> tools;

  factory Enterprise.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final tools = (json['tools'] as List<dynamic>)
        .map((item) => Tool.fromJson(id, item as Map<String, dynamic>))
        .toList();
    return Enterprise(
      id: id,
      name: json['name'] as String,
      tools: tools,
    );
  }

  factory Enterprise.empty() => Enterprise(id: '', name: '', tools: []);
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

  factory Tool.fromJson(String enterpriseId, Map<String, dynamic> json) {
    final platformsJson =
        (json['platforms'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final platforms = <String, ToolPlatform>{};
    platformsJson.forEach((key, value) {
      platforms[key] = ToolPlatform.fromJson(value as Map<String, dynamic>);
    });
    final type = (json['type'] as String?) ??
        (platforms.isNotEmpty ? 'download' : 'web');
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
    );
  }
}

String? _normalizeWorkingDir(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
