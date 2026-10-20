import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/gig_booking.dart';
import '../../../../core/models/vendor_dispute.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../vendor/data/vendor_repository.dart';

class HelpDisputesPage extends StatefulWidget {
  const HelpDisputesPage({super.key});

  @override
  State<HelpDisputesPage> createState() => _HelpDisputesPageState();
}

class _HelpDisputesPageState extends State<HelpDisputesPage> {
  List<VendorDispute> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await VendorRepository.instance.getDisputes();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) _notice('Could not load your support requests.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _newRequest() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewSupportRequestPage()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: AppBar(
      title: const Text('Help & disputes'),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.brandForest,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newRequest,
      backgroundColor: AppColors.brandForest,
      foregroundColor: Colors.white,
      icon: const Icon(LucideIcons.plus),
      label: const Text('New request'),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandForest,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 180),
                Icon(
                  LucideIcons.messageCircleQuestion,
                  size: 44,
                  color: AppColors.mutedText,
                ),
                SizedBox(height: 14),
                Center(child: Text('No support requests yet')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _DisputeCard(dispute: _items[index]),
            ),
    ),
  );
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute});
  final VendorDispute dispute;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DisputeDetailPage(id: dispute.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.brandForest.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageCircle,
                size: 19,
                color: AppColors.brandForest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dispute.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandForest,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${dispute.reference} · ${dispute.categoryLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: dispute.status),
          ],
        ),
      ),
    ),
  );
}

class NewSupportRequestPage extends StatefulWidget {
  const NewSupportRequestPage({super.key});
  @override
  State<NewSupportRequestPage> createState() => _NewSupportRequestPageState();
}

class _NewSupportRequestPageState extends State<NewSupportRequestPage> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  List<DisputeCategory> _categories = const [];
  String _type = 'DISPUTE';
  String? _category;
  GigBooking? _booking;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await VendorRepository.instance.getDisputeCategories();
      if (mounted)
        setState(() {
          _categories = categories;
          _category = categories.firstOrNull?.key;
        });
    } catch (_) {
      if (mounted) _notice('Could not load categories. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _submit() async {
    if (_category == null ||
        _subject.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      _notice('Choose a category and describe the issue.');
      return;
    }
    setState(() => _saving = true);
    try {
      await VendorRepository.instance.createDispute(
        type: _type,
        category: _category!,
        subject: _subject.text.trim(),
        description: _description.text.trim(),
        bookingId: _booking?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _notice('Could not send your request. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Contact support'),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.brandForest,
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'What do you need?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask a question or raise an issue for our support team.',
                style: TextStyle(color: AppColors.mutedText),
              ),
              const SizedBox(height: 22),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'HELP', label: Text('Ask for help')),
                  ButtonSegment(value: 'DISPUTE', label: Text('Raise dispute')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Issue category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.key, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<GigBooking?>(
                value: _booking,
                decoration: const InputDecoration(
                  labelText: 'Related job (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<GigBooking?>(
                    value: null,
                    child: Text('Not about a job'),
                  ),
                  ...AppState.instance.historyBookings.map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text('${b.skill.title} · ${b.customerName}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _booking = value),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _subject,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Describe what happened',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send to support'),
              ),
            ],
          ),
  );
}

class DisputeDetailPage extends StatefulWidget {
  const DisputeDetailPage({super.key, required this.id});
  final String id;
  @override
  State<DisputeDetailPage> createState() => _DisputeDetailPageState();
}

class _DisputeDetailPageState extends State<DisputeDetailPage> {
  VendorDispute? _dispute;
  bool _loading = true;
  bool _sending = false;
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final item = await VendorRepository.instance.getDispute(widget.id);
      if (mounted) setState(() => _dispute = item);
    } catch (_) {
      if (mounted) _notice('Could not load this request.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _reply() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final updated = await VendorRepository.instance.replyToDispute(
        widget.id,
        _message.text.trim(),
      );
      _message.clear();
      if (mounted) setState(() => _dispute = updated);
    } catch (_) {
      if (mounted) _notice('Could not send reply.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    setState(() => _sending = true);
    try {
      final updated = await VendorRepository.instance.closeDispute(widget.id);
      if (mounted) setState(() => _dispute = updated);
    } catch (_) {
      if (mounted) _notice('Could not close request.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _dispute;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.reference ?? 'Support request'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        actions: [
          if (d?.canClose == true)
            TextButton(
              onPressed: _sending ? null : _close,
              child: const Text('Close'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
          ? const SizedBox()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        d.subject,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandForest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: d.status),
                      const SizedBox(height: 14),
                      Text(d.description),
                      if (d.resolution != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Resolution: ${d.resolution}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      const Divider(height: 32),
                      for (final m in d.messages)
                        Align(
                          alignment: m.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(11),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? AppColors.brandForest
                                  : const Color(0xFFF0EEE8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.body,
                              style: TextStyle(
                                color: m.mine
                                    ? Colors.white
                                    : AppColors.brandForest,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (d.canReply)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _message,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Write a reply',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _sending ? null : _reply,
                            icon: const Icon(LucideIcons.send),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'CLOSED' => AppColors.mutedText,
      'RESOLVED' => const Color(0xFF16A34A),
      'IN_PROGRESS' => const Color(0xFF2563EB),
      _ => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
