import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/vendor_wallet.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../vendor/data/vendor_repository.dart';

/// S7 tab 3 — wallet-style earnings (client wallet page layout):
/// big total earned, pending/available amount cards and one
/// payout row per completed booking.
class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  WalletSummary? _wallet;
  PendingWalletEarnings? _pending;
  List<WalletTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final repo = VendorRepository.instance;
      final results = await Future.wait<Object>([
        repo.getWallet(),
        repo.getWalletTransactions(),
        repo.getPendingWalletEarnings(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as WalletSummary;
        _transactions = results[1] as List<WalletTransaction>;
        _pending = results[2] as PendingWalletEarnings;
      });
    } on StateError {
      // Repository is intentionally unavailable in isolated widget tests.
    } catch (_) {
      // Keep the previous values visible; pull-to-refresh can retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandForest,
          onRefresh: _refresh,
          child: ValueListenableBuilder<List<GigBooking>>(
            valueListenable: AppState.instance.bookings,
            builder: (context, bookings, _) {
              final completed = bookings
                  .where(
                    (booking) => booking.status == GigBookingStatus.completed,
                  )
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      children: [
                        const _Header(),
                        const SizedBox(height: 30),
                        _BalanceSummary(
                          total:
                              _wallet?.balance.toInt() ??
                              AppState.instance.totalEarned,
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: _WalletAmountCard(
                                title: 'Pending payout',
                                amount: _formatAmount(
                                  _pending?.onHold.toInt() ??
                                      _wallet?.onHold.toInt() ??
                                      AppState.instance.pendingPayout,
                                ),
                                accent: AppColors.brandGold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WalletAmountCard(
                                title: 'Available balance',
                                amount: _formatAmount(
                                  _wallet?.readyForPayout.toInt() ??
                                      AppState.instance.availableBalance,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 112),
                      children: [
                        if (_transactions.isNotEmpty) ...[
                          const _SectionHeader(title: 'Transactions'),
                          const SizedBox(height: 14),
                          _WalletTransactionsCard(transactions: _transactions),
                          const SizedBox(height: 24),
                        ],
                        if (completed.isNotEmpty) ...[
                          const _SectionHeader(title: 'Completed jobs'),
                          const SizedBox(height: 14),
                          _PayoutsCard(bookings: completed),
                        ] else if (_transactions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 72),
                            child: EmptyState(
                              icon: LucideIcons.wallet,
                              title: 'No wallet activity yet',
                              subtitle: 'Completed jobs and payouts will appear here.',
                            ),
                          ),
                      ],
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Earnings',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wallet, color: AppColors.mutedText, size: 18),
            SizedBox(width: 8),
            Text(
              'Wallet balance',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                '₹',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _formatAmount(total),
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WalletAmountCard extends StatelessWidget {
  const _WalletAmountCard({
    required this.title,
    required this.amount,
    this.accent,
  });

  final String title;
  final String amount;

  /// Amount accent — gold for the pending payout card,
  /// null (forest) for the available balance card.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final amountColor = accent ?? AppColors.brandForest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (accent != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '₹',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                amount,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutsCard extends StatelessWidget {
  const _PayoutsCard({required this.bookings});

  final List<GigBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: partnerCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < bookings.length; i++) ...[
            _PayoutRow(booking: bookings[i]),
            if (i != bookings.length - 1)
              const Divider(height: 1, color: AppColors.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class _WalletTransactionsCard extends StatelessWidget {
  const _WalletTransactionsCard({required this.transactions});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    transactions[i].type == 'PAYOUT'
                        ? LucideIcons.arrowUpRight
                        : LucideIcons.arrowDownLeft,
                    size: 18,
                    color: AppColors.brandForest,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transactions[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          transactions[i].status.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(transactions[i].amount.toInt())}',
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i != transactions.length - 1)
              const Divider(height: 1, color: AppColors.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.booking});

  final GigBooking booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: booking.skill.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              booking.skill.icon,
              size: 20,
              color: AppColors.brandForest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.skill.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.slotLabel,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(booking.payout)}',
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

String _formatAmount(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}
