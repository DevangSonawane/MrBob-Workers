import '../models/kyc_document.dart';

/// Mock data returned by the simulated document "scan" +
/// field extraction (§8 demo rules: auto-fill after ~2s).
class MockExtraction {
  const MockExtraction._();

  static const aadhar = KycDocument(
    type: KycDocType.aadhar,
    number: '123456789012',
    holderName: 'RAMESH KUMAR',
    dob: '15/08/1990',
    imagePath: '/tmp/mock_aadhar_scan.jpg',
  );

  static const pan = KycDocument(
    type: KycDocType.pan,
    number: 'ABCDE1234F',
    holderName: 'RAMESH KUMAR',
    dob: '15/08/1990',
    imagePath: '/tmp/mock_pan_scan.jpg',
  );
}
