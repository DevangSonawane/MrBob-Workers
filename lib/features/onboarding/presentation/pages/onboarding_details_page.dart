import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/onboarding/onboarding_application.dart';
import '../../../../core/models/onboarding/onboarding_category.dart';
import '../../../../core/models/onboarding/onboarding_document.dart';
import '../../../../core/models/onboarding/onboarding_personal_details.dart';
import '../../../../core/models/onboarding/onboarding_services.dart';
import '../../../../core/models/onboarding/onboarding_zone.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/onboarding_repository.dart';
import 'onboarding_phone_page.dart';
import 'onboarding_verification_page.dart';

class OnboardingDetailsPage extends StatefulWidget {
  const OnboardingDetailsPage({super.key, required this.phone});

  final String phone;

  @override
  State<OnboardingDetailsPage> createState() => _OnboardingDetailsPageState();
}

class _OnboardingDetailsPageState extends State<OnboardingDetailsPage> {
  final _repo = OnboardingRepository.instance;
  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  OnboardingApplication? _app;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _emailController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _emgNameController = TextEditingController();
  final _emgPhoneController = TextEditingController();
  final _cityController = TextEditingController();

  String _gender = 'MALE';
  List<OnboardingZone> _zones = <OnboardingZone>[];
  List<OnboardingCategory> _categories = <OnboardingCategory>[];
  String? _selectedHomeZoneId;

  final _selectedCategoryIds = <String>{};
  int _experienceYears = 0;

  final _aadhaarController = TextEditingController();
  final _aadhaarNameController = TextEditingController();
  String? _aadhaarFront;
  String? _aadhaarBack;

  final _panController = TextEditingController();
  final _panNameController = TextEditingController();
  String? _panFront;
  String? _panBack;

  final _bankHolderController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankNameController = TextEditingController();
  String _bankAccountType = 'SAVINGS';
  final _bankBranchController = TextEditingController();
  final _bankUpiController = TextEditingController();
  String? _bankProof;

  String? _profilePhotoPath;
  bool _profilePhotoLoading = false;
  bool _aadhaarLoading = false;
  bool _panLoading = false;
  bool _bankLoading = false;

  int _expandedPart = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _emailController.dispose();
    _altPhoneController.dispose();
    _landmarkController.dispose();
    _emgNameController.dispose();
    _emgPhoneController.dispose();
    _cityController.dispose();
    _aadhaarController.dispose();
    _aadhaarNameController.dispose();
    _panController.dispose();
    _panNameController.dispose();
    _bankHolderController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _bankUpiController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final app = await _repo.getApplication();
      final categories = await _repo.getCategories();
      if (!mounted) return;
      setState(() {
        _app = app;
        _categories = categories;
        _error = null;
      });
      _populateFromApplication(app);
      if (app.personalDetails?.cityId != null &&
          app.personalDetails!.cityId.isNotEmpty) {
        final zones = await _repo.getZones(app.personalDetails!.cityId);
        if (!mounted) return;
        setState(() => _zones = zones);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e.response?.data?['message'] as String? ?? 'Load failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populateFromApplication(OnboardingApplication app) {
    final pd = app.personalDetails;
    if (pd != null) {
      _nameController.text = pd.name;
      _dobController.text = pd.dateOfBirth;
      _gender = pd.gender;
      _cityController.text = pd.cityId;
      _address1Controller.text = pd.addressLine1;
      _address2Controller.text = pd.addressLine2 ?? '';
      _pincodeController.text = pd.pincode;
      _stateController.text = pd.state;
      _emailController.text = pd.email ?? '';
      _altPhoneController.text = pd.alternatePhone ?? '';
      _landmarkController.text = pd.landmark ?? '';
      _emgNameController.text = pd.emergencyContactName ?? '';
      _emgPhoneController.text = pd.emergencyContactPhone ?? '';
    }
    final svc = app.services;
    if (svc != null) {
      _selectedCategoryIds
        ..clear()
        ..addAll(svc.categories);
      _experienceYears = svc.experienceYears;
      _selectedHomeZoneId = svc.homeZoneId;
    }
    final docs = app.documents ?? <OnboardingDocument>[];
    for (final doc in docs) {
      if (doc.type == 'AADHAAR') {
        _aadhaarNameController.text = doc.nameOnDocument ?? '';
      } else if (doc.type == 'PAN') {
        _panNameController.text = doc.nameOnDocument ?? '';
      }
    }
    final bank = app.bankDetails;
    if (bank != null) {
      _bankHolderController.text = bank.accountHolderName ?? '';
      _bankAccountController.text = bank.accountNumber ?? '';
      _bankIfscController.text = bank.ifsc ?? '';
      _bankNameController.text = bank.bankName ?? '';
      _bankAccountType = bank.accountType?.isNotEmpty == true
          ? bank.accountType!
          : 'SAVINGS';
      _bankBranchController.text = bank.branchName ?? '';
      _bankUpiController.text = bank.upiId ?? '';
    }
  }

  bool get _isEditable => _app?.isEditable ?? true;
  bool get _canSubmit => _app?.canSubmit ?? false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xfile == null) return;
    if (!mounted) return;
    try {
      final compressed = await ImageCompressor.compress(File(xfile.path));
      if (!mounted) return;
      setState(() => _profilePhotoPath = compressed.path);
    } catch (_) {
      if (!mounted) return;
      setState(() => _profilePhotoPath = xfile.path);
    }
  }

  Future<void> _saveProfilePhoto() async {
    if (_profilePhotoPath == null) return;
    setState(() => _profilePhotoLoading = true);
    try {
      final result = await _repo.saveProfilePhoto(_profilePhotoPath!);
      if (!mounted) return;
      setState(() {
        _app = result;
        _profilePhotoLoading = false;
        _profilePhotoPath = null;
        _error = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _profilePhotoLoading = false);
      _showError(
        e.response?.data?['message'] as String? ??
            'Failed to save profile photo',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _profilePhotoLoading = false);
      _showError('Network error');
    }
  }

  Future<void> _savePersonalDetails() async {
    if (!_formKey.currentState!.validate()) return;
    final details = OnboardingPersonalDetails(
      name: _nameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      gender: _gender,
      cityId: _cityController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      pincode: _pincodeController.text.trim(),
      state: _stateController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      alternatePhone: _altPhoneController.text.trim().isEmpty
          ? null
          : _altPhoneController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      emergencyContactName:
          _emgNameController.text.trim().isEmpty ? null : _emgNameController.text.trim(),
      emergencyContactPhone:
          _emgPhoneController.text.trim().isEmpty ? null : _emgPhoneController.text.trim(),
    );
    if (details.cityId.isEmpty) {
      _showError('Enter a city');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _repo.savePersonalDetails(details);
      if (!mounted) return;
      setState(() {
        _app = result;
        _saving = false;
        _error = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.response?.data?['message'] as String? ?? 'Save failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Network error');
    }
  }

  Future<void> _saveServices() async {
    if (_selectedCategoryIds.isEmpty) {
      _showError('Select at least one service');
      return;
    }
    final services = OnboardingServices(
      categories: _selectedCategoryIds.toList(),
      experienceYears: _experienceYears,
      homeZoneId: _selectedHomeZoneId,
    );
    setState(() => _saving = true);
    try {
      final result = await _repo.saveServices(services);
      if (!mounted) return;
      setState(() {
        _app = result;
        _saving = false;
        _error = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.response?.data?['message'] as String? ?? 'Save failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Network error');
    }
  }

  Future<void> _saveAadhaar() async {
    final number = _aadhaarController.text.trim();
    final nameOnDoc = _aadhaarNameController.text.trim();
    if (number.isEmpty || nameOnDoc.isEmpty) {
      _showError('Enter Aadhaar number and name');
      return;
    }
    setState(() => _aadhaarLoading = true);
    try {
      final result = await _repo.saveAadhaar(
        number: number,
        nameOnDocument: nameOnDoc,
        frontPath: _aadhaarFront,
        backPath: _aadhaarBack,
      );
      if (!mounted) return;
      setState(() {
        _app = result;
        _aadhaarLoading = false;
        _error = null;
        _aadhaarFront = null;
        _aadhaarBack = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _aadhaarLoading = false);
      _showError(e.response?.data?['message'] as String? ?? 'Save failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _aadhaarLoading = false);
      _showError('Network error');
    }
  }

  Future<void> _savePan() async {
    final number = _panController.text.trim();
    final nameOnDoc = _panNameController.text.trim();
    if (number.isEmpty || nameOnDoc.isEmpty) {
      _showError('Enter PAN number and name');
      return;
    }
    setState(() => _panLoading = true);
    try {
      final result = await _repo.savePan(
        number: number,
        nameOnDocument: nameOnDoc,
        frontPath: _panFront,
        backPath: _panBack,
      );
      if (!mounted) return;
      setState(() {
        _app = result;
        _panLoading = false;
        _error = null;
        _panFront = null;
        _panBack = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _panLoading = false);
      _showError(e.response?.data?['message'] as String? ?? 'Save failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _panLoading = false);
      _showError('Network error');
    }
  }

  Future<void> _saveBankDetails() async {
    final holder = _bankHolderController.text.trim();
    final account = _bankAccountController.text.trim();
    final ifsc = _bankIfscController.text.trim();
    final bankName = _bankNameController.text.trim();
    if (holder.isEmpty || account.isEmpty || ifsc.isEmpty || bankName.isEmpty) {
      _showError('Fill all required bank fields');
      return;
    }
    setState(() => _bankLoading = true);
    try {
      final result = await _repo.saveBankDetails(
        accountHolderName: holder,
        accountNumber: account,
        ifsc: ifsc,
        bankName: bankName,
        accountType: _bankAccountType,
        branchName: _bankBranchController.text.trim().isEmpty
            ? null
            : _bankBranchController.text.trim(),
        upiId: _bankUpiController.text.trim().isEmpty
            ? null
            : _bankUpiController.text.trim(),
        proofPath: _bankProof,
      );
      if (!mounted) return;
      setState(() {
        _app = result;
        _bankLoading = false;
        _error = null;
        _bankProof = null;
      });
      AppHaptics.success();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _bankLoading = false);
      _showError(e.response?.data?['message'] as String? ?? 'Save failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _bankLoading = false);
      _showError('Network error');
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await _repo.submitApplication();
      if (!mounted) return;
      AppHaptics.success();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingVerificationPage(phone: widget.phone),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final missing = e.response?.data?['details']?['missing'];
      if (missing != null && missing is List) {
        final firstMissing = missing.first as String?;
        _showError('Missing: $firstMissing');
      } else {
        _showError(
          e.response?.data?['message'] as String? ?? 'Submit failed',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Network error');
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
    AppHaptics.press();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandForest),
        ),
      );
    }

    final isEditable = _isEditable;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingPhonePage(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandForest,
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(LucideIcons.chevronLeft, size: 25),
                    ),
                    Expanded(
                      child: Text(
                        'Vendor Details',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              _ProgressIndicator(
                currentStep: _app?.flow?.currentStep ?? 3,
              ),
              Expanded(
                child: _error != null
                    ? _ErrorView(
                        message: _error!,
                        onRetry: _load,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _Part(
                                index: 0,
                                title: 'Personal Details',
                                icon: LucideIcons.user,
                                isComplete: _isPartComplete('personalDetails'),
                                isExpanded: _expandedPart == 0,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 0 ? -1 : 0,
                                ),
                                child: _PersonalDetailsForm(
                                  nameController: _nameController,
                                  dobController: _dobController,
                                  address1Controller: _address1Controller,
                                  address2Controller: _address2Controller,
                                  pincodeController: _pincodeController,
                                  stateController: _stateController,
                                  emailController: _emailController,
                                  altPhoneController: _altPhoneController,
                                  landmarkController: _landmarkController,
                                  emgNameController: _emgNameController,
                                  emgPhoneController: _emgPhoneController,
                                  gender: _gender,
                                  cityController: _cityController,
                                  zones: _zones,
                                  selectedHomeZoneId: _selectedHomeZoneId,
                                  onGenderChanged: (v) =>
                                      setState(() => _gender = v),
                                  onCityChanged: (v) {
                                    _cityController.text = v;
                                  },
                                  onHomeZoneChanged: (v) =>
                                      setState(() => _selectedHomeZoneId = v),
                                  isEditable: isEditable,
                                  onSave: _savePersonalDetails,
                                  saving: _saving,
                                ),
                              ),
                              _Part(
                                index: 1,
                                title: 'Profile Photo',
                                icon: LucideIcons.camera,
                                isComplete: _isPartComplete('profilePhoto'),
                                isExpanded: _expandedPart == 1,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 1 ? -1 : 1,
                                ),
                                child: _ProfilePhotoForm(
                                  photoPath: _profilePhotoPath,
                                  onPick: () => _pickImage(ImageSource.gallery),
                                  onSave: _saveProfilePhoto,
                                  saving: _profilePhotoLoading,
                                  isEditable: isEditable,
                                ),
                              ),
                              _Part(
                                index: 2,
                                title: 'Services',
                                icon: LucideIcons.briefcase,
                                isComplete: _isPartComplete('services'),
                                isExpanded: _expandedPart == 2,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 2 ? -1 : 2,
                                ),
                                child: _ServicesForm(
                                  categories: _categories,
                                  selectedCategoryIds: _selectedCategoryIds,
                                  experienceYears: _experienceYears,
                                  zones: _zones,
                                  selectedHomeZoneId: _selectedHomeZoneId,
                                  onCategoryToggle: (id) => setState(() {
                                    if (_selectedCategoryIds.contains(id)) {
                                      _selectedCategoryIds.remove(id);
                                    } else {
                                      _selectedCategoryIds.add(id);
                                    }
                                  }),
                                  onExperienceChanged: (v) =>
                                      setState(() => _experienceYears = v),
                                  onHomeZoneChanged: (v) =>
                                      setState(() => _selectedHomeZoneId = v),
                                  isEditable: isEditable,
                                  onSave: _saveServices,
                                  saving: _saving,
                                ),
                              ),
                              _Part(
                                index: 3,
                                title: 'Aadhaar',
                                icon: LucideIcons.fileText,
                                isComplete: _isPartComplete('aadhaar'),
                                isExpanded: _expandedPart == 3,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 3 ? -1 : 3,
                                ),
                                child: _DocumentForm(
                                  numberController: _aadhaarController,
                                  nameController: _aadhaarNameController,
                                  frontPath: _aadhaarFront,
                                  backPath: _aadhaarBack,
                                  onPickFront: () async {
                                    final xfile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1920,
                                      imageQuality: 85,
                                    );
                                    if (xfile != null && mounted) {
                                      setState(() => _aadhaarFront = xfile.path);
                                    }
                                  },
                                  onPickBack: () async {
                                    final xfile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1920,
                                      imageQuality: 85,
                                    );
                                    if (xfile != null && mounted) {
                                      setState(() => _aadhaarBack = xfile.path);
                                    }
                                  },
                                  onSave: _saveAadhaar,
                                  saving: _aadhaarLoading,
                                  isEditable: isEditable,
                                ),
                              ),
                              _Part(
                                index: 4,
                                title: 'PAN',
                                icon: LucideIcons.fileText,
                                isComplete: _isPartComplete('pan'),
                                isExpanded: _expandedPart == 4,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 4 ? -1 : 4,
                                ),
                                child: _DocumentForm(
                                  numberController: _panController,
                                  nameController: _panNameController,
                                  frontPath: _panFront,
                                  backPath: _panBack,
                                  onPickFront: () async {
                                    final xfile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1920,
                                      imageQuality: 85,
                                    );
                                    if (xfile != null && mounted) {
                                      setState(() => _panFront = xfile.path);
                                    }
                                  },
                                  onPickBack: () async {
                                    final xfile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1920,
                                      imageQuality: 85,
                                    );
                                    if (xfile != null && mounted) {
                                      setState(() => _panBack = xfile.path);
                                    }
                                  },
                                  onSave: _savePan,
                                  saving: _panLoading,
                                  isEditable: isEditable,
                                ),
                              ),
                              _Part(
                                index: 5,
                                title: 'Bank Details',
                                icon: LucideIcons.wallet,
                                isComplete: _isPartComplete('bankDetails'),
                                isExpanded: _expandedPart == 5,
                                onToggle: () => setState(
                                  () => _expandedPart =
                                      _expandedPart == 5 ? -1 : 5,
                                ),
                                child: _BankDetailsForm(
                                  holderController: _bankHolderController,
                                  accountController: _bankAccountController,
                                  ifscController: _bankIfscController,
                                  bankNameController: _bankNameController,
                                  accountType: _bankAccountType,
                                  branchController: _bankBranchController,
                                  upiController: _bankUpiController,
                                  proofPath: _bankProof,
                                  onPickProof: () async {
                                    final xfile = await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1920,
                                      imageQuality: 85,
                                    );
                                    if (xfile != null && mounted) {
                                      setState(() => _bankProof = xfile.path);
                                    }
                                  },
                                  onAccountTypeChanged: (v) =>
                                      setState(() => _bankAccountType = v),
                                  onSave: _saveBankDetails,
                                  saving: _bankLoading,
                                  isEditable: isEditable,
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!isEditable)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.brandGold,
                                    ),
                                  ),
                                  child: const Text(
                                    'Application is under review. '
                                    'Details cannot be edited right now.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.brandForest,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: PrimaryButton(
                                  label: _canSubmit
                                      ? 'Submit Application'
                                      : 'Complete all parts to submit',
                                  onTap: _canSubmit && !_submitting && isEditable
                                      ? _submit
                                      : () {},
                                  enabled: _canSubmit && isEditable && !_submitting,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  bool _isPartComplete(String key) {
    return (_app?.detailSteps ?? const <DetailStep>[])
        .any((s) => s.key == key && s.complete);
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.index,
    required this.title,
    required this.icon,
    required this.isComplete,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final int index;
  final String title;
  final IconData icon;
  final bool isComplete;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppColors.radiusCard),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.brandForest
                          : AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isComplete ? LucideIcons.check : icon,
                      size: 18,
                      color: isComplete ? Colors.white : AppColors.brandForest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++) ...[
            _StepDot(step: i, currentStep: currentStep),
            if (i != 5)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i <= currentStep
                      ? AppColors.brandForest
                      : AppColors.borderSubtle,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.currentStep});

  final int step;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final done = step < currentStep;
    final current = step == currentStep;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: current
            ? AppColors.brandGold
            : done
                ? AppColors.brandForest
                : AppColors.borderSubtle,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
          : Text(
              '$step',
              style: TextStyle(
                color: current ? AppColors.brandForest : AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-forms ───────────────────────────────────────────────────────────────

class _PersonalDetailsForm extends StatefulWidget {
  const _PersonalDetailsForm({
    required this.nameController,
    required this.dobController,
    required this.address1Controller,
    required this.address2Controller,
    required this.pincodeController,
    required this.stateController,
    required this.emailController,
    required this.altPhoneController,
    required this.landmarkController,
    required this.emgNameController,
    required this.emgPhoneController,
    required this.gender,
    required this.cityController,
    required this.zones,
    required this.selectedHomeZoneId,
    required this.onGenderChanged,
    required this.onCityChanged,
    required this.onHomeZoneChanged,
    required this.isEditable,
    required this.onSave,
    required this.saving,
  });

  final TextEditingController nameController;
  final TextEditingController dobController;
  final TextEditingController address1Controller;
  final TextEditingController address2Controller;
  final TextEditingController pincodeController;
  final TextEditingController stateController;
  final TextEditingController emailController;
  final TextEditingController altPhoneController;
  final TextEditingController landmarkController;
  final TextEditingController emgNameController;
  final TextEditingController emgPhoneController;
  final String gender;
  final TextEditingController cityController;
  final List<OnboardingZone> zones;
  final String? selectedHomeZoneId;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String?> onHomeZoneChanged;
  final bool isEditable;
  final VoidCallback onSave;
  final bool saving;

  @override
  State<_PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<_PersonalDetailsForm> {
  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.isEditable;
    return Column(
      children: [
        _field('Full Name (as on Aadhaar)', widget.nameController, readOnly, required: true),
        _field('Date of Birth (YYYY-MM-DD)', widget.dobController, readOnly, required: true),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Gender',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (readOnly)
          Text(
            widget.gender,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Row(
            children: ['MALE', 'FEMALE', 'OTHER']
                .map(
                  (g) => Expanded(
                    child: _GenderPill(
                      label: g,
                      selected: widget.gender == g,
                      onTap: () => widget.onGenderChanged(g),
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        _field('City', widget.cityController, readOnly, required: true),
        const SizedBox(height: 8),
        _field('Address Line 1', widget.address1Controller, readOnly, required: true),
        _field('Address Line 2', widget.address2Controller, readOnly, required: false),
        _field('Pincode', widget.pincodeController, readOnly, required: true, keyboardType: TextInputType.number),
        _field('State', widget.stateController, readOnly, required: true),
        _field('Email', widget.emailController, readOnly, required: false, keyboardType: TextInputType.emailAddress),
        _field('Alternate Phone', widget.altPhoneController, readOnly, required: false, keyboardType: TextInputType.phone),
        _field('Landmark', widget.landmarkController, readOnly, required: false),
        if (widget.emgNameController.text.isNotEmpty ||
            widget.emgPhoneController.text.isNotEmpty) ...[
          _field('Emergency Contact Name', widget.emgNameController, readOnly, required: false),
          _field('Emergency Contact Phone', widget.emgPhoneController, readOnly, required: false, keyboardType: TextInputType.phone),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: readOnly ? null : widget.saving ? null : widget.onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
            ),
            child: widget.saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Personal Details'),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    bool readOnly, {
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (!readOnly && required && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandForest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandForest : AppColors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.brandForest,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoForm extends StatelessWidget {
  const _ProfilePhotoForm({
    required this.photoPath,
    required this.onPick,
    required this.onSave,
    required this.saving,
    required this.isEditable,
  });

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onSave;
  final bool saving;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          )
        else
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(
              LucideIcons.camera,
              size: 32,
              color: AppColors.mutedText,
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEditable ? onPick : null,
                icon: const Icon(LucideIcons.image, size: 16),
                label: const Text('Choose Photo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    isEditable && !saving && photoPath != null ? onSave : null,
                icon: saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.upload, size: 16),
                label: Text(saving ? 'Saving...' : 'Upload'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServicesForm extends StatefulWidget {
  const _ServicesForm({
    required this.categories,
    required this.selectedCategoryIds,
    required this.experienceYears,
    required this.zones,
    required this.selectedHomeZoneId,
    required this.onCategoryToggle,
    required this.onExperienceChanged,
    required this.onHomeZoneChanged,
    required this.isEditable,
    required this.onSave,
    required this.saving,
  });

  final List<OnboardingCategory> categories;
  final Set<String> selectedCategoryIds;
  final int experienceYears;
  final List<OnboardingZone> zones;
  final String? selectedHomeZoneId;
  final ValueChanged<String> onCategoryToggle;
  final ValueChanged<int> onExperienceChanged;
  final ValueChanged<String?> onHomeZoneChanged;
  final bool isEditable;
  final VoidCallback onSave;
  final bool saving;

  @override
  State<_ServicesForm> createState() => _ServicesFormState();
}

class _ServicesFormState extends State<_ServicesForm> {
  String? _selectedHomeZoneId;

  @override
  void initState() {
    super.initState();
    _selectedHomeZoneId = widget.selectedHomeZoneId;
  }

  @override
  void didUpdateWidget(covariant _ServicesForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHomeZoneId != widget.selectedHomeZoneId) {
      _selectedHomeZoneId = widget.selectedHomeZoneId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.isEditable;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories
              .map(
                (c) => FilterChip(
                  label: Text(c.name),
                  selected: widget.selectedCategoryIds.contains(c.id),
                  onSelected: readOnly ? null : (v) => widget.onCategoryToggle(c.id),
                  selectedColor: AppColors.brandForest,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: widget.selectedCategoryIds.contains(c.id)
                        ? Colors.white
                        : AppColors.brandForest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: widget.experienceYears.toString(),
          readOnly: readOnly,
          decoration: const InputDecoration(
            labelText: 'Experience (years)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) widget.onExperienceChanged(n);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedHomeZoneId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Home Zone',
            border: OutlineInputBorder(),
          ),
          items: widget.zones
              .map((z) => DropdownMenuItem(value: z.id, child: Text(z.name)))
              .toList(),
          onChanged: readOnly
              ? null
              : (v) {
                  setState(() => _selectedHomeZoneId = v);
                  if (v != null) widget.onHomeZoneChanged(v);
                },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: readOnly || widget.saving ? null : widget.onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
            ),
            child: widget.saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Services'),
          ),
        ),
      ],
    );
  }
}

class _DocumentForm extends StatelessWidget {
  const _DocumentForm({
    required this.numberController,
    required this.nameController,
    required this.frontPath,
    required this.backPath,
    required this.onPickFront,
    required this.onPickBack,
    required this.onSave,
    required this.saving,
    required this.isEditable,
  });

  final TextEditingController numberController;
  final TextEditingController nameController;
  final String? frontPath;
  final String? backPath;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;
  final VoidCallback onSave;
  final bool saving;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final readOnly = !isEditable;
    return Column(
      children: [
        _docField('Number', numberController, readOnly),
        _docField('Name on Document', nameController, readOnly),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: readOnly ? null : onPickFront,
                icon: const Icon(LucideIcons.image, size: 16),
                label: Text(frontPath == null ? 'Front' : 'Change Front'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: readOnly ? null : onPickBack,
                icon: const Icon(LucideIcons.image, size: 16),
                label: Text(backPath == null ? 'Back' : 'Change Back'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: readOnly || saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
            ),
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Document'),
          ),
        ),
      ],
    );
  }

  Widget _docField(String label, TextEditingController c, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.characters,
      ),
    );
  }
}

class _BankDetailsForm extends StatelessWidget {
  const _BankDetailsForm({
    required this.holderController,
    required this.accountController,
    required this.ifscController,
    required this.bankNameController,
    required this.accountType,
    required this.branchController,
    required this.upiController,
    required this.proofPath,
    required this.onPickProof,
    required this.onAccountTypeChanged,
    required this.onSave,
    required this.saving,
    required this.isEditable,
  });

  final TextEditingController holderController;
  final TextEditingController accountController;
  final TextEditingController ifscController;
  final TextEditingController bankNameController;
  final String accountType;
  final TextEditingController branchController;
  final TextEditingController upiController;
  final String? proofPath;
  final VoidCallback onPickProof;
  final ValueChanged<String> onAccountTypeChanged;
  final VoidCallback onSave;
  final bool saving;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final readOnly = !isEditable;
    return Column(
      children: [
        _docField('Account Holder Name', holderController, readOnly),
        _docField('Account Number', accountController, readOnly,
            keyboardType: TextInputType.number),
        _docField('IFSC Code', ifscController, readOnly),
        _docField('Bank Name', bankNameController, readOnly),
        const SizedBox(height: 8),
        if (readOnly)
          Text(
            accountType,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: accountType,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'SAVINGS', child: Text('Savings')),
              DropdownMenuItem(value: 'CURRENT', child: Text('Current')),
            ],
            onChanged: (v) {
              if (v != null) onAccountTypeChanged(v);
            },
          ),
        _docField('Branch Name', branchController, readOnly),
        _docField('UPI ID', upiController, readOnly),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: readOnly ? null : onPickProof,
          icon: const Icon(LucideIcons.fileText, size: 16),
          label: Text(proofPath == null ? 'Attach Proof' : 'Change Proof'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: readOnly || saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandForest,
              foregroundColor: Colors.white,
            ),
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Bank Details'),
          ),
        ),
      ],
    );
  }

  Widget _docField(
    String label,
    TextEditingController c,
    bool readOnly, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}
