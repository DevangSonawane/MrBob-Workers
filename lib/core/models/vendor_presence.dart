/// Vendor presence — the H3 dispatch heartbeat.
///
/// The server keeps a vendor's online state, their last known position and
/// the H3 cell they sit in. Offers are only routed to vendors that are
/// online *and* that keep sending a position (no position for 5 minutes
/// means no offers; after 15 minutes the server flips the vendor offline).
class VendorPresence {
  const VendorPresence({
    this.online = false,
    this.latitude,
    this.longitude,
    this.h3Cell,
    this.lastSeenAt,
    this.onlineSince,
    this.canReceiveOffers = true,
    this.activeOffers = 0,
    this.updateEverySeconds = 30,
  });

  /// Whether the server currently considers this vendor online.
  final bool online;

  /// Last position the server stored for this vendor.
  final double? latitude;
  final double? longitude;

  /// H3 cell (hexagon) the stored position falls into.
  final String? h3Cell;

  /// Server timestamp of the last position update.
  final DateTime? lastSeenAt;

  /// When the vendor went online.
  final DateTime? onlineSince;

  /// False while online means the vendor is not approved yet, so the app
  /// shows "Your profile is under review" instead of job offers.
  final bool canReceiveOffers;

  /// How many offers are currently open for this vendor.
  final int activeOffers;

  /// How often the app should push a new position while online.
  final int updateEverySeconds;

  bool get hasPosition => latitude != null && longitude != null;

  /// The vendor is online but still waiting for approval.
  bool get awaitingApproval => online && !canReceiveOffers;

  factory VendorPresence.fromJson(Map<String, dynamic> json) {
    return VendorPresence(
      online: json['online'] == true,
      latitude: _readDouble(json, const ['latitude', 'lat']),
      longitude: _readDouble(json, const ['longitude', 'lng', 'lon']),
      h3Cell: _readString(json, const ['h3Cell', 'h3', 'cell']),
      lastSeenAt: DateTime.tryParse(
        _readString(json, const ['lastSeenAt', 'lastSeen']) ?? '',
      )?.toLocal(),
      onlineSince: DateTime.tryParse(
        _readString(json, const ['onlineSince']) ?? '',
      )?.toLocal(),
      canReceiveOffers: json['canReceiveOffers'] != false,
      activeOffers: _readInt(json, const ['activeOffers']) ?? 0,
      updateEverySeconds: _readInt(json, const ['updateEverySeconds']) ?? 30,
    );
  }

  VendorPresence copyWith({
    bool? online,
    double? latitude,
    double? longitude,
    String? h3Cell,
    DateTime? lastSeenAt,
    DateTime? onlineSince,
    bool? canReceiveOffers,
    int? activeOffers,
    int? updateEverySeconds,
  }) {
    return VendorPresence(
      online: online ?? this.online,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      h3Cell: h3Cell ?? this.h3Cell,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      onlineSince: onlineSince ?? this.onlineSince,
      canReceiveOffers: canReceiveOffers ?? this.canReceiveOffers,
      activeOffers: activeOffers ?? this.activeOffers,
      updateEverySeconds: updateEverySeconds ?? this.updateEverySeconds,
    );
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
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
