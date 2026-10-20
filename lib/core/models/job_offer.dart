/// A time-boxed job offer addressed to this vendor.
///
/// H3 dispatches a job in waves: wave 1 goes to the closest vendors, then
/// wider rings. A vendor that gets an offer has [expiresAt] seconds to
/// accept it before the next wave opens up and the offer is withdrawn.
class JobOffer {
  const JobOffer({required this.expiresAt, this.wave});

  /// When the offer expires (server time, UTC).
  final DateTime expiresAt;

  /// Dispatch wave this offer belongs to (1 = closest ring).
  final int? wave;

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      wave: _readInt(json, const ['wave']),
    );
  }
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
  }
  return null;
}
