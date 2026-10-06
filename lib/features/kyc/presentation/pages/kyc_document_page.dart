import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/data/mock_worker.dart';
import '../../../../core/models/kyc_document.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/primary_button.dart';
import 'kyc_verifying_page.dart';

/// S4 — document details: type selector, manual entry
/// (Aadhar/PAN), simulated scan + extraction, validation.
class KycDocumentPage extends StatefulWidget {
  const KycDocumentPage({super.key});

  @override
  State<KycDocumentPage> createState() => _KycDocumentPageState();
}

class _KycDocumentPageState extends State<KycDocumentPage> {
  KycDocType _type = KycDocType.aadhar;

  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();

  final _numberFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();

  /// Local path from the simulated scan, attached to the
  /// [KycDocument] on submit.
  String? _imagePath;

  /// Extraction animation in flight (progress + "Extracting details…").
  bool _extracting = false;

  /// Mock extraction finished — shows the green chip.
  bool _extracted = false;

  @override
  void initState() {
    super.initState();
    _numberController.addListener(_onFieldsChanged);
    _nameController.addListener(_onFieldsChanged);
    _dobController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _numberFocus.dispose();
    _nameFocus.dispose();
    _dobFocus.dispose();
    super.dispose();
  }

  void _onFieldsChanged() => setState(() {});

  // ------------------------------------------------------------------
  // Validation (live — errors clear as soon as the field is valid)
  // ------------------------------------------------------------------

  String? get _numberError {
    final raw = _numberController.text.trim();
    if (raw.isEmpty) return null;
    if (_type == KycDocType.aadhar) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 12) return 'Enter the full 12-digit Aadhar number';
      return null;
    }
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(raw)) {
      return 'Enter a valid PAN (format AAAAA9999A)';
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  void _selectType(KycDocType type) {
    if (type == _type) return;
    AppHaptics.tick();
    setState(() {
      _type = type;
      // Formats differ between documents — start the number over.
      _numberController.clear();
      _imagePath = null;
      _extracted = false;
      _extracting = false;
    });
  }

  Future<void> _scanCard() async {
    AppHaptics.press();
    final type = _type;
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.camera);
    } catch (_) {
      picked = null;
    }
    // Camera unavailable/denied — fall back to the gallery.
    if (picked == null) {
      try {
        picked = await picker.pickImage(source: ImageSource.gallery);
      } catch (_) {
        picked = null;
      }
    }
    if (!mounted) return;
    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan cancelled — you can enter details manually'),
        ),
      );
      return;
    }
    final imagePath = picked.path;

    setState(() {
      _extracting = true;
      _extracted = false;
    });
    // Simulated OCR: ~2s, then auto-fill from the mock extraction.
    Timer(const Duration(seconds: 2), () {
      if (!mounted || _type != type) return;
      final mock = type == KycDocType.aadhar
          ? MockExtraction.aadhar
          : MockExtraction.pan;
      _numberController.text = type == KycDocType.aadhar
          ? _groupDigits(mock.number, 4)
          : mock.number;
      _nameController.text = mock.holderName;
      _dobController.text = mock.dob;
      setState(() {
        _extracting = false;
        _extracted = true;
        _imagePath = imagePath;
      });
    });
  }

  void _submit() {
    final doc = KycDocument(
      type: _type,
      number: _type == KycDocType.aadhar
          ? _numberController.text.replaceAll(RegExp(r'\D'), '')
          : _numberController.text.trim(),
      holderName: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      imagePath: _imagePath,
    );
    final profile = AppState.instance.profile.value;
    AppState.instance.updateProfile(
      profile.copyWith(kycDocument: doc, kycStatus: KycStatus.submitted),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KycVerifyingPage()),
    );
  }

  void _back() {
    AppHaptics.press();
    Navigator.pop(context);
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final numberError = _numberError;
    final isAadhar = _type == KycDocType.aadhar;

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                    child: Row(
                      children: [
                        _BackButton(onTap: _back),
                        Expanded(
                          child: Text(
                            'Verify your identity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        keyboardInset + bottomInset + 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _DocTypePill(
                            selected: _type,
                            onChanged: _selectType,
                          ),
                          const SizedBox(height: 16),
                          if (_extracting)
                            const _ExtractingIndicator()
                          else if (_extracted)
                            const _ExtractedChip()
                          else
                            _ScanButton(onTap: _scanCard),
                          const SizedBox(height: 20),
                          const _OrDivider(),
                          const SizedBox(height: 18),
                          _Field(
                            label: isAadhar ? 'Aadhar number' : 'PAN number',
                            controller: _numberController,
                            focusNode: _numberFocus,
                            hint: isAadhar ? '#### #### ####' : 'AAAAA9999A',
                            error: numberError,
                            keyboardType: isAadhar
                                ? TextInputType.number
                                : TextInputType.text,
                            textCapitalization: isAadhar
                                ? TextCapitalization.none
                                : TextCapitalization.characters,
                            inputFormatters: isAadhar
                                ? [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                    const _GroupedDigitsFormatter(size: 4),
                                  ]
                                : [
                                    LengthLimitingTextInputFormatter(10),
                                    const _UpperCaseAlphanumericFormatter(),
                                  ],
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            label: 'Holder name',
                            controller: _nameController,
                            focusNode: _nameFocus,
                            hint: 'Name as printed on the card',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                          _Field(
                            label: 'Date of birth',
                            controller: _dobController,
                            focusNode: _dobFocus,
                            hint: 'DD/MM/YYYY',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                              const _DobFormatter(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                  child: PrimaryButton(
                    label: 'Verify & continue',
                    onTap: _submit,
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

class _DocTypePill extends StatelessWidget {
  const _DocTypePill({
    required this.selected,
    required this.onChanged,
  });

  final KycDocType selected;
  final ValueChanged<KycDocType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: selected == KycDocType.aadhar
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 24,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandForest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                _PillOption(
                  type: KycDocType.aadhar,
                  selected: selected == KycDocType.aadhar,
                  onTap: () => onChanged(KycDocType.aadhar),
                ),
                _PillOption(
                  type: KycDocType.pan,
                  selected: selected == KycDocType.pan,
                  onTap: () => onChanged(KycDocType.pan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final KycDocType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = type == KycDocType.aadhar ? 'Aadhar' : 'PAN';
    return Expanded(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Semantics(
          key: ValueKey<String>('$type-${selected ? "on" : "off"}'),
          button: true,
          selected: selected,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              key: ValueKey<bool>(selected),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF525252),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E5E5),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE5E5E5),
          ),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan card',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.brandForest,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandForest.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                LucideIcons.scanLine,
                size: 21,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                'Scan card',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtractingIndicator extends StatelessWidget {
  const _ExtractingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(
          color: AppColors.brandGold.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandForest,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Extracting details…',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtractedChip extends StatelessWidget {
  const _ExtractedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2E8),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.checkCircle, size: 17, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text(
            'Details extracted',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.label,
    this.error,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String? label;
  final String? error;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() =>
      setState(() => _focused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.brandForest : const Color(0xFFE7E9EF),
              width: _focused ? 1.4 : 1.1,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
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
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9EA2AE),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              isCollapsed: true,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.error!,
            style: const TextStyle(
              color: Color(0xFFCE2E30),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Inserts a space every [size] digits — Aadhar `#### #### ####`.
class _GroupedDigitsFormatter extends TextInputFormatter {
  const _GroupedDigitsFormatter({required this.size});

  final int size;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = _groupDigits(digits, size);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// PAN: uppercase alphanumeric only.
class _UpperCaseAlphanumericFormatter extends TextInputFormatter {
  const _UpperCaseAlphanumericFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// DOB: `DD/MM/YYYY` with auto-inserted slashes.
class _DobFormatter extends TextInputFormatter {
  const _DobFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = _formatDob(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String _groupDigits(String digits, int size) {
  final chunks = <String>[];
  for (var i = 0; i < digits.length; i += size) {
    chunks.add(digits.substring(i, math.min(i + size, digits.length)));
  }
  return chunks.join(' ');
}

String _formatDob(String digits) {
  if (digits.length <= 2) return digits;
  if (digits.length <= 4) {
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }
  return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
}
