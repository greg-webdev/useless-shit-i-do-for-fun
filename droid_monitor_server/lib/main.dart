import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/file_storage_service.dart';
import 'services/https_server_service.dart';
import 'services/system_telemetry_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DroidMonitorApp());
}

class DroidMonitorApp extends StatelessWidget {
  const DroidMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DroidMonitor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF4FACFE),
          surface: Color(0xFF111728),
        ),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final HttpsServerService _server = HttpsServerService();
  bool _isServerRunning = false;
  bool _wakeLockEnabled = true;
  Timer? _telemetryTimer;

  Map<String, dynamic> _stats = {
    'cpu': {'usagePercent': 0.0, 'cores': 8},
    'memory': {'usedPercent': 0.0, 'usedBytes': 0, 'totalBytes': 0},
    'thermal': {'batteryTemp': 30.0, 'cpuTemp': 35.0, 'batteryLevel': 100},
  };

  int _fileCount = 0;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Keep device awake by default
    if (_wakeLockEnabled) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }

    // Auto-start HTTPS server on port 1212
    await _startServer();

    // Start periodic polling for local UI display
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshTelemetry());
    _refreshTelemetry();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    // Do NOT stop server here! Keep server & telemetry running in background!
    super.dispose();
  }

  Future<void> _startServer() async {
    final ok = await _server.start(port: 1212);
    if (mounted) {
      setState(() {
        _isServerRunning = ok;
      });
    }
  }

  Future<void> _stopServer() async {
    await _server.stop();
    if (mounted) {
      setState(() {
        _isServerRunning = false;
      });
    }
  }

  Future<void> _toggleServer(bool value) async {
    if (value) {
      await _startServer();
    } else {
      await _stopServer();
    }
  }

  Future<void> _refreshTelemetry() async {
    final stats = await SystemTelemetryService.getStats();
    final files = await FileStorageService.listFiles();
    if (mounted) {
      setState(() {
        _stats = stats;
        _fileCount = files.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryUrl = _server.serverUrls.isNotEmpty ? _server.serverUrls.first : 'https://127.0.0.1:1212';
    final cpuUsage = ((_stats['cpu']?['usagePercent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0);
    final ramUsage = ((_stats['memory']?['usedPercent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0);
    final cpuTemp = ((_stats['thermal']?['cpuTemp'] as num?)?.toDouble() ?? 32.0).toStringAsFixed(1);
    final batteryTemp = ((_stats['thermal']?['batteryTemp'] as num?)?.toDouble() ?? 30.0).toStringAsFixed(1);

    final storageTotalBytes = (_stats['storage']?['totalBytes'] as num?)?.toDouble() ?? (32.0 * 1024 * 1024 * 1024);
    final storageUsedBytes = (_stats['storage']?['usedBytes'] as num?)?.toDouble() ?? (16.0 * 1024 * 1024 * 1024);
    final storageFreeBytes = (_stats['storage']?['freeBytes'] as num?)?.toDouble() ?? (16.0 * 1024 * 1024 * 1024);
    final storageUsedGb = (storageUsedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final storageTotalGb = (storageTotalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final storageFreeGb = (storageFreeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final storagePct = ((_stats['storage']?['usedPercent'] as num?)?.toDouble() ?? 50.0).toStringAsFixed(0);
    final hostedSizeFormatted = (_stats['storage']?['hostedFormatted'] as String?) ?? '0 B';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemTelemetryService.moveTaskToBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1322),
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.security, size: 20, color: Color(0xFF090D16)),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DroidMonitor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  Text(
                    'HTTPS Port 1212',
                    style: TextStyle(fontSize: 11, color: Color(0xFF00F2FE), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Stats',
              onPressed: _refreshTelemetry,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Server Control Card
          _buildServerControlCard(primaryUrl),

          const SizedBox(height: 16),

          // Live Telemetry Mini-Grid
          _buildTelemetryCards(
            cpuUsage,
            ramUsage,
            cpuTemp,
            batteryTemp,
            storagePct,
            storageUsedGb,
            storageTotalGb,
            storageFreeGb,
            hostedSizeFormatted,
          ),

          const SizedBox(height: 16),

          // Screen Snapshot Card
          _buildScreenshotCard(),

          const SizedBox(height: 16),

          // QR Code Card for Instant Access
          if (_isServerRunning) _buildQrCard(primaryUrl),

          const SizedBox(height: 16),

          // Settings & Options Card
          _buildSettingsCard(),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

  Widget _buildServerControlCard(String primaryUrl) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isServerRunning ? const Color(0x6600F2FE) : const Color(0x33FFFFFF),
          width: 1.5,
        ),
        boxShadow: [
          if (_isServerRunning)
            BoxShadow(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isServerRunning ? const Color(0xFF00F5A0) : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (_isServerRunning)
                          const BoxShadow(
                            color: Color(0xFF00F5A0),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isServerRunning ? 'HTTPS SERVER RUNNING' : 'SERVER STOPPED',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isServerRunning ? const Color(0xFF00F5A0) : Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isServerRunning,
                activeThumbColor: const Color(0xFF00F2FE),
                activeTrackColor: const Color(0x5500F2FE),
                onChanged: _toggleServer,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Open this address in any browser on your Wi-Fi network:',
            style: TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B101D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x2200F2FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Color(0xFF00F2FE)),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    primaryUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00F2FE),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                  tooltip: 'Copy URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: primaryUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Server HTTPS URL copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_server.serverUrls.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Other interfaces: ${_server.serverUrls.skip(1).join(', ')}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryCards(
    String cpuUsage,
    String ramUsage,
    String cpuTemp,
    String batteryTemp,
    String storagePct,
    String storageUsedGb,
    String storageTotalGb,
    String storageFreeGb,
    String hostedSizeFormatted,
  ) {
    final double storageProgress = ((double.tryParse(storagePct) ?? 50.0) / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE DEVICE TELEMETRY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B949E), letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'CPU USAGE',
                value: '$cpuUsage%',
                subtext: '${_stats['cpu']?['cores'] ?? 8} Cores',
                accentColor: const Color(0xFF00F2FE),
                icon: Icons.memory,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'RAM USAGE',
                value: '$ramUsage%',
                subtext: 'Active',
                accentColor: const Color(0xFF4FACFE),
                icon: Icons.pie_chart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'TEMPERATURE',
                value: '$cpuTemp°C',
                subtext: 'Bat: $batteryTemp°C',
                accentColor: const Color(0xFFF6D365),
                icon: Icons.thermostat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'HOSTED FILES',
                value: '$_fileCount',
                subtext: hostedSizeFormatted,
                accentColor: const Color(0xFF00F5A0),
                icon: Icons.folder_shared,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dedicated Storage Usage Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage, size: 16, color: Color(0xFFC471ED)),
                      SizedBox(width: 8),
                      Text(
                        'STORAGE USED',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B949E)),
                      ),
                    ],
                  ),
                  Text(
                    '$storagePct%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC471ED),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: storageProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC471ED)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Used: $storageUsedGb GB / $storageTotalGb GB',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFE6EDF3)),
                  ),
                  Text(
                    'Free: $storageFreeGb GB',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF00F5A0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B949E)),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(String url) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2200F2FE)),
      ),
      child: Column(
        children: [
          const Text(
            'SCAN TO OPEN DASHBOARD',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B949E), letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 160.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Point your computer, tablet, or phone camera to quickly access the web dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF6E7681)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SERVER SETTINGS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B949E), letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep Device Awake', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Prevents OS sleep and Wi-Fi throttling while serving files', style: TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
            value: _wakeLockEnabled,
            activeThumbColor: const Color(0xFF00F2FE),
            onChanged: (val) async {
              setState(() {
                _wakeLockEnabled = val;
              });
              if (val) {
                await WakelockPlus.enable();
              } else {
                await WakelockPlus.disable();
              }
            },
          ),
          const Divider(color: Color(0x1AFFFFFF)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF8B949E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Browser Warning: On first visit, click "Advanced -> Proceed" to accept the local self-signed TLS certificate.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt, color: Color(0xFF00F2FE), size: 20),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCREEN SNAPSHOT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Capture current screen view',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_camera, size: 16),
            label: const Text('Capture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F2FE),
              foregroundColor: const Color(0xFF090D16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showScreenCaptureDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _showScreenCaptureDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00F2FE)),
      ),
    );

    final bytes = await SystemTelemetryService.captureScreenshot();
    if (mounted) Navigator.of(context).pop();

    if (bytes != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text('Device Screen Snapshot', style: TextStyle(fontSize: 16, color: Colors.white)),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00F2FE))),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screen capture not available')),
      );
    }
  }
}
