import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// Debug screen showing app configuration and system info
/// Only visible in debug mode
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String? _apiStatus;
  bool _isTestingApi = false;
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _loadUserToken();
  }

  Future<void> _loadUserToken() async {
    final token = await AuthService.getValidToken();
    setState(() {
      _userToken = token;
    });
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingApi = true;
      _apiStatus = 'Testing...';
    });

    try {
      final url = '${AppConfig.apiBaseUrl}/';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      setState(() {
        _apiStatus = 'Status: ${response.statusCode}\n'
            'Response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...';
        _isTestingApi = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Error: $e';
        _isTestingApi = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AdsyToast.success(context, 'Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      // Don't show debug screen in release mode
      return Scaffold(
        appBar: AppBar(title: const Text('Debug')),
        body: const Center(
          child: Text('Debug screen only available in development mode'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Debug Information',
          style: AppFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Environment Card
          _buildCard(
            title: 'Environment',
            icon: Icons.public,
            color: AppConfig.isDevelopment ? Colors.orange : Colors.green,
            children: [
              _buildInfoRow('Mode', AppConfig.environment),
              _buildInfoRow('Is Development', '${AppConfig.isDevelopment}'),
              _buildInfoRow('Is Production', '${AppConfig.isProduction}'),
              _buildInfoRow('Debug Mode', '$kDebugMode'),
              _buildInfoRow('Release Mode', '$kReleaseMode'),
            ],
          ),

          const SizedBox(height: 16),

          // API Configuration Card
          _buildCard(
            title: 'API Configuration',
            icon: Icons.api,
            color: Colors.blue,
            children: [
              _buildInfoRow(
                'API Base URL',
                AppConfig.apiBaseUrl,
                onTap: () => _copyToClipboard(AppConfig.apiBaseUrl),
              ),
              _buildInfoRow(
                'Media Base URL',
                AppConfig.mediaBaseUrl,
                onTap: () => _copyToClipboard(AppConfig.mediaBaseUrl),
              ),
              const Divider(),
              ElevatedButton.icon(
                onPressed: _isTestingApi ? null : _testApiConnection,
                icon: _isTestingApi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: AdsyLoadingIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label:
                    Text(_isTestingApi ? 'Testing...' : 'Test API Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_apiStatus != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _apiStatus!,
                    style: AppFonts.robotoMono(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Authentication Card
          _buildCard(
            title: 'Authentication',
            icon: Icons.lock,
            color: Colors.purple,
            children: [
              _buildInfoRow('Has Token', '${_userToken != null}'),
              if (_userToken != null) ...[
                _buildInfoRow(
                  'Token (first 20 chars)',
                  '${_userToken!.substring(0,
                          _userToken!.length > 20 ? 20 : _userToken!.length)}...',
                  onTap: () => _copyToClipboard(_userToken!),
                ),
              ],
              const Divider(),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.logout();
                  if (!mounted) return;
                  setState(() {
                    _userToken = null;
                  });
                  if (context.mounted) {
                    AdsyToast.info(context, 'Logged out');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Platform Information Card
          _buildCard(
            title: 'Platform Information',
            icon: Icons.phone_android,
            color: Colors.teal,
            children: [
              _buildInfoRow('Platform', defaultTargetPlatform.toString()),
              _buildInfoRow('Is Web', '$kIsWeb'),
              _buildInfoRow('Screen Size', '${MediaQuery.of(context).size}'),
              _buildInfoRow(
                  'Pixel Ratio', '${MediaQuery.of(context).devicePixelRatio}'),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Actions Card
          _buildCard(
            title: 'Quick Actions',
            icon: Icons.build,
            color: Colors.amber,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.blue),
                title: const Text('Reload App'),
                subtitle: const Text('Hot reload (Debug only)'),
                onTap: () {
                  // In debug mode, this will trigger hot reload
                  if (kDebugMode) {
                    AdsyToast.info(context, 'Press R in console for hot reload');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.red),
                title: const Text('Show Config in Console'),
                subtitle: const Text('Print configuration to console'),
                onTap: () {
                  AppConfig.printConfig();
                  AdsyToast.info(context, 'Config printed to console');
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions Card
          _buildCard(
            title: 'How to Switch Environments',
            icon: Icons.info_outline,
            color: Colors.indigo,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Development Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Run: flutter run'),
                    Text('• Default: local backend'),
                    Text('• Android emulator: http://10.0.2.2:8000'),
                    Text('• Desktop/iOS: http://localhost:8000'),
                    SizedBox(height: 12),
                    Text(
                      '📱 Physical Device:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        '• Run with: --dart-define=LOCAL_API_HOST=192.168.x.x:8000'),
                    SizedBox(height: 12),
                    Text(
                      '🚀 Production Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Run with: --dart-define=USE_LOCAL_API=false'),
                    Text('• Or build release APK'),
                    SizedBox(height: 12),
                    Text(
                      '📝 Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('API URL prints in console on app startup.'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 16, color: Colors.grey.shade600),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
