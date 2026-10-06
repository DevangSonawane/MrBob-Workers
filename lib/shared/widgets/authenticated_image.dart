import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/onboarding/data/onboarding_repository.dart';

class AuthenticatedImage extends StatefulWidget {
  const AuthenticatedImage({
    super.key,
    required this.path,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String path;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });

    try {
      final dio = OnboardingRepository.instance.dio;
      final response = await dio.get(
        widget.path,
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(response.data);
        _loading = false;
        _error = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      if (status == 404) {
        setState(() {
          _loading = false;
          _error = 'NOT_FOUND';
        });
      } else if (status == 503) {
        setState(() {
          _loading = false;
          _error = 'UNAVAILABLE';
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'ERROR';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'ERROR';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandForest),
          ),
        ),
      );
    }

    if (_error != null) {
      if (_error == 'NOT_FOUND') {
        return _placeholder;
      }
      if (_error == 'UNAVAILABLE') {
        return _unavailableWidget;
      }
      return _placeholder;
    }

    if (_bytes == null) {
      return _placeholder;
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      child: Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      ),
    );
  }

  Widget get _placeholder {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(
            LucideIcons.imageOff,
            size: 24,
            color: AppColors.mutedText,
          ),
        );
  }

  Widget get _unavailableWidget {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.wifiOff, size: 20, color: AppColors.mutedText),
              const SizedBox(height: 6),
              Text(
                'Try again later',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
  }
}
