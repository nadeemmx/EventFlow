import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:eventflow_app/core/theme/app_colors.dart';
import 'package:eventflow_app/core/theme/app_dimens.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showReconnected = false;
  Timer? _reconnectedTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOffline = offline;
      });
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (mounted) {
      setState(() {
        if (_isOffline && !offline) {
          _showReconnected = true;
          _reconnectedTimer?.cancel();
          _reconnectedTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showReconnected = false;
              });
            }
          });
        }
        _isOffline = offline;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _reconnectedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDimens.animNormal,
      curve: AppDimens.curveDefault,
      child: AnimatedOpacity(
        duration: AppDimens.animNormal,
        opacity: _isOffline ? 1.0 : (_showReconnected ? 1.0 : 0.0),
        child: _isOffline
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.lg,
                  vertical: AppDimens.sm,
                ),
                color: AppColors.error,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: AppDimens.iconSm,
                    ),
                    SizedBox(width: AppDimens.sm),
                    Text(
                      "You're offline",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppDimens.fontSm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : (_showReconnected
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg,
                      vertical: AppDimens.sm,
                    ),
                    color: AppColors.success,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          color: Colors.white,
                          size: AppDimens.iconSm,
                        ),
                        SizedBox(width: AppDimens.sm),
                        Text(
                          'Back online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppDimens.fontSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}
