import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/job_session.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import 'job_complete_page.dart';

/// Upload photos of completed work page.
class UploadImagesPage extends StatefulWidget {
  const UploadImagesPage({super.key, required this.booking});

  final GigBooking booking;

  @override
  State<UploadImagesPage> createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends State<UploadImagesPage> {
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _goingToComplete = false;
  bool _popped = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }

    try {
      final remaining = 5 - _selectedImages.length;
      final picked = await _picker.pickMultiImage(limit: remaining);
      if (picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }

    try {
      final photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadAndContinue() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final multipartFiles = <MultipartFile>[];
      for (final image in _selectedImages) {
        multipartFiles.add(await MultipartFile.fromFile(
          image.path,
          filename: 'completion_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}.jpg',
        ));
      }

      await AppState.instance.uploadCompletionImages(multipartFiles);
      if (!mounted) return;
      _goToCompleteOnce();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _goToCompleteOnce() {
    if (_goingToComplete || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _goingToComplete = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => JobCompletePage(booking: widget.booking),
      ),
    );
  }

  void _popOnce() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.brandForest, size: 20),
          onPressed: () {
            AppHaptics.press();
            Navigator.pop(context);
          },
        ),
        title: const Text('Upload photos',
            style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<JobSession?>(
            valueListenable: AppState.instance.activeJob,
            builder: (context, session, _) {
              if (session == null ||
                  session.booking.id != widget.booking.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _popOnce());
                return const SizedBox.shrink();
              }
              if (session.phase == JobPhase.completed) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _goToCompleteOnce());
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      children: [
                        const Text('Step 4 of 4 · Upload photos',
                            style: TextStyle(
                                color: AppColors.mutedText, fontSize: 12)),
                        const SizedBox(height: 6),
                        _ThinBar(fraction: 1.0),
                        const SizedBox(height: 12),
                        _JobLine(booking: widget.booking),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Photos of finished work',
                                      style: TextStyle(
                                          color: AppColors.brandForest,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                  const Spacer(),
                                  Text('${_selectedImages.length}/5',
                                      style: const TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                  'Upload 1-5 photos (JPEG, PNG, WebP, max 5MB each)',
                                  style: TextStyle(
                                      color: AppColors.mutedText, fontSize: 12)),
                              const SizedBox(height: 16),
                              if (_selectedImages.isNotEmpty) ...[
                                SizedBox(
                                  height: 100,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, index) =>
                                        _ImageThumbnail(
                                      image: _selectedImages[index],
                                      onRemove: () => _removeImage(index),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: _ImageSourceButton(
                                      icon: LucideIcons.camera,
                                      label: 'Take photo',
                                      onTap: _takePhoto,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ImageSourceButton(
                                      icon: LucideIcons.image,
                                      label: 'From gallery',
                                      onTap: _pickImages,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.booking.completionImages.isNotEmpty) ...[
                          const Text('Previously uploaded',
                              style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.booking.completionImages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) =>
                                  _ExistingImageThumbnail(
                                image: widget.booking.completionImages[index],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
                    child: GestureDetector(
                      onTap: _isUploading ? null : _uploadAndContinue,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: _selectedImages.isEmpty || _isUploading
                              ? AppColors.brandForest.withValues(alpha: 0.5)
                              : AppColors.brandForest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue to complete',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThinBar extends StatelessWidget {
  const _ThinBar({required this.fraction});
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brandForest,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _JobLine extends StatelessWidget {
  const _JobLine({required this.booking});
  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: booking.skill.color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(booking.skill.icon,
                color: AppColors.brandForest, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.skill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('${booking.customerName} · ${booking.slotLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.mutedText, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.image,
    required this.onRemove,
  });

  final XFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
            image: DecorationImage(
              image: FileImage(File(image.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExistingImageThumbnail extends StatelessWidget {
  const _ExistingImageThumbnail({required this.image});

  final CompletionImage image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
        image: DecorationImage(
          image: NetworkImage(image.url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.brandForest),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}