import 'dart:math' as math;

import '../models/gig_booking.dart';
import 'skills_data.dart';

/// Worker's demo-fixed current location: Andheri East, Mumbai
/// (same anchor the client app uses for its fake GPS).
const workerLatitude = 19.2836;
const workerLongitude = 72.8727;

const _firstNames = [
  'Aarav',
  'Priya',
  'Rohan',
  'Sneha',
  'Vikram',
  'Ananya',
  'Karan',
  'Meera',
  'Arjun',
  'Divya',
];

const _lastNames = [
  'Sharma',
  'Patel',
  'Gupta',
  'Nair',
  'Khan',
  'Iyer',
  'Desai',
  'Menon',
  'Joshi',
  'Rao',
];

const _buildings = [
  'Green Heights',
  'Sapphire Residency',
  'Lakeview Apartments',
  'Sunrise Enclave',
  'Palm Grove',
  'Silver Oak Society',
  'Royal Garden',
  'Shree Siddhi Villa',
  'Ocean Pearl',
  'Harmony Nest',
];

const _areas = [
  'Andheri East',
  'Andheri West',
  'Bandra West',
  'Juhu',
  'Borivali West',
  'Goregaon East',
  'Malad West',
  'Dadar East',
  'Powai',
  'Vile Parle West',
];

const _landmarks = [
  'near Metro station',
  'opposite Big Bazaar',
  'next to Hanuman Mandir',
  'behind the market',
  'near the bus depot',
  'off Link Road',
  'near the park',
  'above the pharmacy',
];

const _notesPool = [
  'Gate code 4412, please call on arrival.',
  'Parking is tight — two-wheeler preferred.',
  'Customer is elderly, please be patient.',
  'Materials already bought, on the kitchen table.',
  'Society office needs a visitor pass.',
  'Flat 2B, ring the bell twice.',
  'Dog on site, friendly but excited.',
  'Water supply is shut from 10 AM.',
];

/// Deterministic mock booking generator. [seed] drives the
/// pseudo-random pick so injected bookings stay varied but stable.
GigBooking generateMockBooking(int seed) {
  final random = math.Random(seed * 97 + 13);
  final skill = skills[random.nextInt(skills.length)];
  final name =
      '${_firstNames[random.nextInt(_firstNames.length)]} '
      '${_lastNames[random.nextInt(_lastNames.length)]}';
  final building = _buildings[random.nextInt(_buildings.length)];
  final area = _areas[random.nextInt(_areas.length)];
  final landmark = _landmarks[random.nextInt(_landmarks.length)];
  final floor = random.nextInt(4) + 1;
  final distance = 2.0 + random.nextDouble() * 4.0;
  final eta = (distance * 3.2).round();
  final payout = skill.id == 'inspection'
      ? 999
      : (349 + random.nextInt(7) * 50);
  final platformFee = 29;
  final asap = random.nextBool();
  final hour = 9 + random.nextInt(9);
  final minute = random.nextBool() ? '00' : '30';
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : hour;

  // Destination within ~2–6 km of the worker anchor.
  final lat = workerLatitude + (random.nextDouble() - 0.5) * 0.09;
  final lng = workerLongitude + (random.nextDouble() - 0.5) * 0.11;

  return GigBooking(
    id: 'GB${1000 + seed}',
    skill: skill,
    customerName: name,
    customerRating: 3.9 + random.nextDouble() * 1.1,
    addressLine:
        '$floor${_floorSuffix(floor)} Floor, $building, $area, Mumbai, Maharashtra 400069',
    landmark: landmark,
    latitude: lat,
    longitude: lng,
    distanceKm: double.parse(distance.toStringAsFixed(1)),
    etaMinutes: eta,
    slotLabel: asap
        ? 'ASAP'
        : 'Today, $displayHour:$minute $period',
    payout: payout,
    platformFee: platformFee,
    notes: _notesPool[random.nextInt(_notesPool.length)],
    durationLabel: skill.id == 'inspection'
        ? '2.5 hr'
        : '${45 + random.nextInt(6) * 15} min',
  );
}

String _floorSuffix(int floor) {
  if (floor == 1) return 'st';
  if (floor == 2) return 'nd';
  if (floor == 3) return 'rd';
  return 'th';
}

/// Seed feed: six pending bookings around the worker's location.
final mockBookings = <GigBooking>[
  for (var seed = 1; seed <= 6; seed++) generateMockBooking(seed),
];
