import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_haptics.dart';

/// Four boxed OTP inputs driven by one hidden text field
/// (client-app pattern from `email_login_page.dart`).
/// Digits-only, length-locked to 4, auto-submits at 4.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.onCompleted,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final VoidCallback onCompleted;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    setState(() {});
    if (widget.controller.text.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;

    return GestureDetector(
      onTap: widget.focusNode.requestFocus,
      child: Stack(
        children: [
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: _OtpBox(
                    value: index < value.length ? value[index] : '',
                    active: widget.focusNode.hasFocus && index == value.length,
                  ),
                ),
                if (index != 3) const SizedBox(width: 12),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.01,
              child: TextField(
                focusNode: widget.focusNode,
                controller: widget.controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onSubmitted: (_) => widget.onCompleted(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.value, required this.active});

  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.brandForest : AppColors.borderSubtle,
          width: active ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.brandForest,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Convenience: haptic + callback wrapper for OTP submit.
void submitOtp(VoidCallback onSubmit) {
  AppHaptics.confirm();
  onSubmit();
}
