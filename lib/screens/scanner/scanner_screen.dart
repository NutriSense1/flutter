import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tracking_providers.dart';
import '../../services/api_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _capture(ImageSource source) async {
    setState(() => _errorMessage = null);

    // On Android/iOS the image_picker plugin handles the permission dialog
    // automatically when you call pickImage. However, on some Android 13+
    // builds the dialog is silently skipped if the activity hasn't been
    // resumed yet after a permission rationale.  We work around this by
    // catching the LostDataResponse pattern and retrying once.
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
    } catch (e) {
      if (!mounted) return;
      // On Android, if the camera is unavailable or permission permanently
      // denied, image_picker throws a PlatformException.
      if (Platform.isAndroid && source == ImageSource.camera) {
        setState(() => _errorMessage =
            'Camera access denied. Please enable camera permission in your device settings, then try again.');
      } else {
        setState(() => _errorMessage = 'Could not access camera or gallery. Please check permissions.');
      }
      return;
    }
    if (picked == null) return; // user cancelled

    setState(() => _isScanning = true);

    try {
      // XFile.readAsBytes() works on every platform (Android/iOS/Web).
      // dart:io's File(picked.path) does NOT work on web — on web,
      // picked.path is a blob: URL, not a real filesystem path, so
      // File().readAsBytes() throws (or silently fails) there. This was
      // why scanning — both gallery AND camera — was broken on web.
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      final api = ref.read(apiServiceProvider);
      final result = await api.scanFood(imageBase64: base64Image);

      ref.read(scanHistoryProvider.notifier).addScan(result);

      if (!mounted) return;
      setState(() => _isScanning = false);
      context.push(AppRoutes.scanResult, extra: result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.statusCode == 402
            ? 'Daily scan limit reached. Upgrade to Premium for unlimited scans.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
              ),
            ),
          ),

          // ── Scan frame ──
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
                    color: _isScanning ? AppColors.accent : AppColors.primary,
                    width: 3,
                  ),
                ),
                child: _isScanning
                    ? Center(
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
                            const SizedBox(height: 4),
                            Text(
                              'Identifying food & checking nutrition',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      )
                    : const Icon(Icons.center_focus_strong_rounded,
                        color: Colors.white24, size: 48),
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
                  const SizedBox(width: 44), // balance the close button
                ],
              ),
            ),
          ),

          // ── Error banner ──
          if (_errorMessage != null)
            Positioned(
              top: 90,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: AppTypography.bodySmall.copyWith(color: Colors.white)),
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
                      _ScannerActionBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: _isScanning ? null : () => _capture(ImageSource.gallery),
                      ),
                      GestureDetector(
                        onTap: _isScanning ? null : () => _capture(ImageSource.camera),
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
                      // Spacer to balance the gallery button (barcode scanning is V2)
                      const SizedBox(width: 52),
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
