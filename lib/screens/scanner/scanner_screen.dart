import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../models/scan_result_model.dart';
import '../../providers/tracking_providers.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    setState(() => _isScanning = true);
    // Simulate API call (2s)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isScanning = false);

    // Mock result
    final result = ScanResultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: 'Greek Yogurt',
      brand: 'Chobani',
      foodType: 'Dairy',
      ingredients: ['Cultured Nonfat Milk', 'Cream', 'Live & Active Cultures'],
      detectedAdditives: [],
      detectedAllergens: ['Dairy'],
      nutritionInfo: const NutritionInfo(
        calories: 130,
        protein: 17,
        carbs: 9,
        fat: 3.5,
        fiber: 0,
        sugar: 7,
        sodium: 65,
        saturatedFat: 2,
      ),
      servingSize: 150,
      servingUnit: 'g',
      healthScore: 82,
      healthScoreLabel: 'Excellent',
      aiVerdict:
          'Excellent choice! Greek yogurt is high in protein and probiotics. '
          'It supports gut health, muscle recovery, and satiety. '
          'The low sugar content and healthy fat profile make this a nutritional powerhouse.',
      positives: ['High protein (17g)', 'Good source of calcium', 'Live probiotics', 'Low sugar'],
      negatives: ['Contains dairy (allergen)'],
      recommendations: [
        'Pair with berries for antioxidants',
        'Add honey for natural sweetness',
        'Great post-workout meal',
      ],
      isUltraProcessed: false,
      confidence: ScanConfidence.high,
      scannedAt: DateTime.now(),
    );

    ref.read(scanHistoryProvider.notifier).addScan(result);
    if (!mounted) return;
    context.push(AppRoutes.scanResult, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Fake Camera Preview ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
              ),
            ),
          ),

          // ── Scanning overlay frame ──
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isScanning ? _pulseAnim.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isScanning
                        ? AppColors.accent
                        : AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    ..._buildCorners(),
                    if (_isScanning)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.accent,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Analysing...',
                              style: AppTypography.titleMedium.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Scan Food',
                    style: AppTypography.titleLarge.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Point camera at food or packaging',
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      _ScannerActionBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: _isScanning ? null : _simulateScan,
                      ),
                      // Shutter
                      GestureDetector(
                        onTap: _isScanning ? null : _simulateScan,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _isScanning ? AppColors.accent : Colors.white,
                          ),
                          child: Icon(
                            Icons.camera_rounded,
                            color: _isScanning ? Colors.white : AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                      // Barcode button
                      _ScannerActionBtn(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Barcode',
                        onTap: _isScanning ? null : _simulateScan,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 4.0;
    final color = _isScanning ? AppColors.accent : AppColors.primary;
    return [
      // Top-left
      Positioned(top: -1, left: -1, child: _Corner(color: color, size: size, thickness: thickness)),
      // Top-right
      Positioned(
          top: -1,
          right: -1,
          child: Transform.rotate(
              angle: 1.5708,
              child: _Corner(color: color, size: size, thickness: thickness))),
      // Bottom-left
      Positioned(
          bottom: -1,
          left: -1,
          child: Transform.rotate(
              angle: -1.5708,
              child: _Corner(color: color, size: size, thickness: thickness))),
      // Bottom-right
      Positioned(
          bottom: -1,
          right: -1,
          child: Transform.rotate(
              angle: 3.1416,
              child: _Corner(color: color, size: size, thickness: thickness))),
    ];
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double thickness;
  const _Corner({required this.color, required this.size, required this.thickness});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(color: color, thickness: thickness),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  const _CornerPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScannerActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ScannerActionBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
