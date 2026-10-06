import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mrbob_partner/features/kyc/presentation/pages/kyc_document_page.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/otp_boxes.dart';
import '../../../../shared/widgets/osm_tile_background.dart';

class OtpSignupPage extends StatefulWidget {
  const OtpSignupPage({super.key, this.phone = ''});

  /// Phone number captured on the login sheet, in E.164 form
  /// ('+91…'). Empty when arriving via the Google/Apple
  /// demo shortcuts.
  final String phone;

  @override
  State<OtpSignupPage> createState() => _OtpSignupPageState();
}

class _OtpSignupPageState extends State<OtpSignupPage> {
  static const _locationAccent = AppColors.brandForest;

  final _pageController = PageController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  int _step = 0;
  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_handleOtpChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_handleOtpChanged);
    _pageController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _otpFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Demo OTP rule: any 4 digits pass — the shared
  /// OtpBoxes auto-submits at 4, advancing the flow.
  void _handleOtpChanged() {
    if (_step != 0) return;
    if (_otpController.text.length == 4) {
      _next();
    }
  }

  String get _buttonLabel => 'Next';

  void _next() {
    if (_step == 0) {
      final otp = _otpController.text.trim();
      if (otp.length != 4) {
        AppHaptics.press();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the 4-digit code')),
        );
        return;
      }
      AppHaptics.confirm();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_step == 1) {
      AppHaptics.confirm();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _completeSignup();
  }

  /// Step 3: demo signup complete — persist the profile
  /// (name, phone, gender, service area) and hand off to KYC.
  void _completeSignup() {
    AppState.instance.updateProfile(
      AppState.instance.profile.value.copyWith(
        name: _nameController.text.trim(),
        phone: widget.phone,
        gender: _gender,
        serviceArea: 'Selected location',
      ),
    );
    AppHaptics.success();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const KycDocumentPage()),
    );
  }

  void _selectGender(String value) {
    AppHaptics.tick();
    setState(() => _gender = value);
  }

  void _back() {
    if (_step == 0) {
      AppHaptics.press();
      Navigator.pop(context);
      return;
    }
    AppHaptics.tick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (_step != 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                      child: Row(
                        children: [
                          _BackButton(onTap: _back),
                          const Spacer(),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) {
                        setState(() => _step = value);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (value == 0) {
                            _otpFocusNode.requestFocus();
                          } else if (value == 1) {
                            _nameFocusNode.requestFocus();
                          } else {
                            FocusScope.of(context).unfocus();
                          }
                        });
                      },
                      children: [
                        _FlowStep(
                          title: 'Verify your phone number',
                          subtitle:
                              'Enter the verification code sent to your phone number.',
                          child: OtpBoxes(
                            focusNode: _otpFocusNode,
                            controller: _otpController,
                            onCompleted: _next,
                          ),
                        ),
                        _FlowStep(
                          title: 'What is your name?',
                          subtitle:
                              'Pros and support will use this for your bookings.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LargeTextField(
                                focusNode: _nameFocusNode,
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _next(),
                              ),
                              const SizedBox(height: 26),
                              _GenderPills(
                                selected: _gender,
                                onSelected: _selectGender,
                              ),
                            ],
                          ),
                        ),
                        _AddressStep(
                          accentColor: _locationAccent,
                          onBack: _back,
                          onConfirm: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_step != 2)
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 0,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      bottom: keyboardInset + 14 + bottomInset * 0.3,
                    ),
                    child: _NextButton(
                      label: _buttonLabel,
                      onTap: _next,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandForest,
          shape: const CircleBorder(),
        ),
        icon: const Icon(LucideIcons.chevronLeft, size: 25),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFB8B8B8),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 26),
          child,
        ],
      ),
    );
  }
}

class _GenderPills extends StatelessWidget {
  const _GenderPills({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _options = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in _options) ...[
          Expanded(
            child: _GenderPill(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
          if (option != _options.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandForest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandForest : AppColors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.brandForest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeTextField extends StatelessWidget {
  const _LargeTextField({
    required this.focusNode,
    required this.controller,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7E9EF), width: 1.1),
      ),
      alignment: Alignment.center,
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: false,
        cursorColor: AppColors.brandForest,
        cursorWidth: 1.5,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        decoration: const InputDecoration(
          hintText: 'Enter your name',
          hintStyle: TextStyle(
            color: Color(0xFF9EA2AE),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _AddressStep extends StatefulWidget {
  const _AddressStep({
    required this.accentColor,
    required this.onBack,
    required this.onConfirm,
  });

  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep>
    with SingleTickerProviderStateMixin {
  Offset _mapOffset = Offset.zero;
  late final AnimationController _recenterController;
  Animation<Offset>? _recenterAnimation;

  @override
  void initState() {
    super.initState();
    _recenterController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addListener(() {
          final animation = _recenterAnimation;
          if (animation == null) return;
          setState(() => _mapOffset = animation.value);
        });
  }

  @override
  void dispose() {
    _recenterController.dispose();
    super.dispose();
  }

  void _dragMap(DragUpdateDetails details) {
    _recenterController.stop();
    setState(() {
      _mapOffset += details.delta;
      _mapOffset = Offset(
        _mapOffset.dx.clamp(-180.0, 180.0),
        _mapOffset.dy.clamp(-220.0, 220.0),
      );
    });
  }

  void _useCurrentLocation() {
    AppHaptics.confirm();
    _recenterAnimation = Tween<Offset>(begin: _mapOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _recenterController,
            curve: Curves.easeOutCubic,
          ),
        );
    _recenterController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _dragMap,
          child: _LocationMap(
            accentColor: widget.accentColor,
            offset: _mapOffset,
          ),
        ),
        Positioned(
          top: 18,
          left: 14,
          right: 14,
          child: Row(
            children: [
              _FloatingMapButton(onTap: widget.onBack),
              const SizedBox(width: 10),
              const Expanded(child: _SearchAddressBox()),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 220 + bottomInset,
          child: _CurrentLocationButton(
            accentColor: widget.accentColor,
            onTap: _useCurrentLocation,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _ConfirmLocationSheet(
            accentColor: widget.accentColor,
            bottomInset: bottomInset,
            onConfirm: widget.onConfirm,
          ),
        ),
      ],
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onTap,
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF9C9C9C),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SearchAddressBox extends StatelessWidget {
  const _SearchAddressBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(LucideIcons.search, color: Color(0xFFA8A8A8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search an area or address',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFA8A8A8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({
    required this.accentColor,
    required this.onTap,
  });

  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Text(
            'Current Location',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmLocationSheet extends StatelessWidget {
  const _ConfirmLocationSheet({
    required this.accentColor,
    required this.bottomInset,
    required this.onConfirm,
  });

  final Color accentColor;
  final double bottomInset;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Your current location is selected',
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, color: accentColor, size: 17),
                    const SizedBox(width: 9),
                    Text(
                      'Confirm Location',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selected location',
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Drag the map to place the pin on your service address.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF8B8B8B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.accentColor, required this.offset});

  final Color accentColor;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        OsmTileBackground(offset: offset),
        Positioned.fill(
          child: Center(
            child: _SelectedLocationPin(accentColor: accentColor),
          ),
        ),
      ],
    );
  }
}

class _SelectedLocationPin extends StatelessWidget {
  const _SelectedLocationPin({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              child: Text(
                'Selected location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: _CalloutPointerClipper(),
            child: Container(width: 18, height: 16, color: accentColor),
          ),
          Container(width: 3, height: 16, color: accentColor),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.24),
                  blurRadius: 14,
                  spreadRadius: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutPointerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _NextButton extends StatefulWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.brandForest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
