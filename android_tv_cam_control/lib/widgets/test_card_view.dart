import 'dart:async';
import 'package:flutter/material.dart';

class TestCardView extends StatefulWidget {
  final String statusMessage;
  final String serverUrl;

  const TestCardView({
    super.key,
    required this.statusMessage,
    required this.serverUrl,
  });

  @override
  State<TestCardView> createState() => _TestCardViewState();
}

class _TestCardViewState extends State<TestCardView>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _timer.cancel();
    _sweepController.dispose();
    super.dispose();
  }

  String _formatTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}.'
        '${(now.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // SMPTE Color Bars: Gray, Yellow, Cyan, Green, Magenta, Red, Blue
    final colors = [
      const Color(0xFFC0C0C0), // 75% White / Light Gray
      const Color(0xFFC0C000), // Yellow
      const Color(0xFF00C0C0), // Cyan
      const Color(0xFF00C000), // Green
      const Color(0xFFC000C0), // Magenta
      const Color(0xFFC00000), // Red
      const Color(0xFF0000C0), // Blue
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Color Bars
        Column(
          children: [
            // Top 66% Bars
            Expanded(
              flex: 2,
              child: Row(
                children: colors.map((c) {
                  return Expanded(child: Container(color: c));
                }).toList(),
              ),
            ),
            // Middle Cast Bars (8%)
            Expanded(
              flex: 0,
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    Expanded(child: Container(color: const Color(0xFF0000C0))),
                    Expanded(child: Container(color: const Color(0xFF131313))),
                    Expanded(child: Container(color: const Color(0xFFC000C0))),
                    Expanded(child: Container(color: const Color(0xFF131313))),
                    Expanded(child: Container(color: const Color(0xFF00C0C0))),
                    Expanded(child: Container(color: const Color(0xFF131313))),
                    Expanded(child: Container(color: const Color(0xFFC0C0C0))),
                  ],
                ),
              ),
            ),
            // Bottom 26% Black & Reference
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF0A0E17),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(color: const Color(0xFF002244)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(color: Colors.white),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'HDMI INPUT WAITING',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Animated Scanline Sweep
        AnimatedBuilder(
          animation: _sweepController,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * _sweepController.value,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Center Cyberpunk Info HUD
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xEE090D16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'STANDBY / TEST PATTERN',
                          style: TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTime(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF00F2FE),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  widget.statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // Server Link Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Control at: ${widget.serverUrl}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Plug in USB capture card or select camera with TV Remote / Phone Controller',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
