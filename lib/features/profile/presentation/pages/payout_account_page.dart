import 'package:flutter/material.dart';

import '../../../../core/models/vendor_wallet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../vendor/data/vendor_repository.dart';

class PayoutAccountPage extends StatefulWidget {
  const PayoutAccountPage({super.key, this.account});

  final PayoutAccount? account;

  @override
  State<PayoutAccountPage> createState() => _PayoutAccountPageState();
}

class _PayoutAccountPageState extends State<PayoutAccountPage> {
  late final TextEditingController _holder;
  late final TextEditingController _number;
  late final TextEditingController _ifsc;
  late final TextEditingController _bank;
  late final TextEditingController _branch;
  late final TextEditingController _upi;
  late String _accountType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _holder = TextEditingController(text: account?.accountHolderName ?? '');
    _number = TextEditingController();
    _ifsc = TextEditingController(text: account?.ifsc ?? '');
    _bank = TextEditingController(text: account?.bankName ?? '');
    _branch = TextEditingController(text: account?.branchName ?? '');
    _upi = TextEditingController(text: account?.upiId ?? '');
    _accountType = account?.accountType ?? 'SAVINGS';
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _ifsc.dispose();
    _bank.dispose();
    _branch.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await VendorRepository.instance.updatePayoutAccount({
        if (_holder.text.trim().isNotEmpty)
          'accountHolderName': _holder.text.trim(),
        if (_number.text.trim().isNotEmpty)
          'accountNumber': _number.text.trim(),
        if (_ifsc.text.trim().isNotEmpty) 'ifsc': _ifsc.text.trim(),
        if (_bank.text.trim().isNotEmpty) 'bankName': _bank.text.trim(),
        if (_branch.text.trim().isNotEmpty) 'branchName': _branch.text.trim(),
        'accountType': _accountType,
        'upiId': _upi.text.trim(),
      });
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save payout details.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payout account'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add your bank account or UPI ID to receive payouts.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Changes require verification before payouts resume.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _field('Account holder name', _holder),
              _field(
                'Account number (only needed to add/change)',
                _number,
                keyboardType: TextInputType.number,
              ),
              _field('IFSC', _ifsc),
              _field('Bank name', _bank),
              _field('Branch name', _branch),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(labelText: 'Account type'),
                items: const [
                  DropdownMenuItem(value: 'SAVINGS', child: Text('Savings')),
                  DropdownMenuItem(value: 'CURRENT', child: Text('Current')),
                ],
                onChanged: (value) =>
                    setState(() => _accountType = value ?? 'SAVINGS'),
              ),
              const SizedBox(height: 12),
              _field('UPI ID', _upi, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGold,
                    foregroundColor: AppColors.brandForest,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _field(
  String label,
  TextEditingController controller, {
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
