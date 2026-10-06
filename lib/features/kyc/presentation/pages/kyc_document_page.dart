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

  bool get _allValid {
    if (_numberController.text.trim().isEmpty) return false;
    if (_numberError != null) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_dobController.text.trim().isEmpty) return false;
    return true;
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
      final mock =
          type == KycDocType.aadhar ? MockExtraction.aadhar : MockExtraction.pan;
      _numberController.text =
          type == KycDocType.aadhar ? _groupDigits(mock.number, 4) : mock.number;
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
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(26, 20, 26, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verify your identity',
                            style: TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Required before you can receive bookings',
                            style: TextStyle(
                              color: Color(0xFFB8B8B8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.22,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              _DocTypeCard(
                                type: KycDocType.aadhar,
                                selected: isAadhar,
                                onTap: () => _selectType(KycDocType.aadhar),
                              ),
                              const SizedBox(width: 10),
                              _DocTypeCard(
                                type: KycDocType.pan,
                                selected: !isAadhar,
                                onTap: () => _selectType(KycDocType.pan),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_extracting)
                            const _ExtractingIndicator()
                          else if (_extracted)
                            const _ExtractedChip()
                          else
                            _ScanButton(onTap: _scanCard),
                          const SizedBox(height: 22),
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
                          const SizedBox(height: 16),
                          _Field(
                            label: 'Holder name',
                            controller: _nameController,
                            focusNode: _nameFocus,
                            hint: 'Name as printed on the card',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
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
                    enabled: _allValid,
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

class _DocTypeCard extends StatelessWidget {
  const _DocTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final KycDocType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAadhar = type == KycDocType.aadhar;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandForest.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppColors.radiusCard),
              border: Border.all(
                color: selected ? AppColors.brandForest : AppColors.borderSubtle,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAadhar ? LucideIcons.idCard : LucideIcons.creditCard,
                  size: 26,
                  color: selected ? AppColors.brandForest : AppColors.mutedText,
                ),
                const SizedBox(height: 12),
                Text(
                  isAadhar ? 'Aadhar Card' : 'PAN Card',
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAadhar ? '12-digit number' : '10-char alphanumeric',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            border: Border.all(color: AppColors.brandForest, width: 1.2),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.scanLine, size: 20, color: AppColors.brandForest),
              SizedBox(width: 8),
              Text(
                'Scan card',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
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
          SizedBox(width: 12),
          Text(
            'Extracting details…',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w600,
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
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2E8),
        borderRadius: BorderRadius.circular(AppColors.radiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.checkCircle, size: 16, color: Color(0xFF2E7D32)),
          SizedBox(width: 6),
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

  void _onFocusChanged() => setState(() => _focused = widget.focusNode.hasFocus);

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
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
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
