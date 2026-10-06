

class OnboardingFlowStep {
  final int step;
  final String key;
  final String title;
  final String status;

  OnboardingFlowStep({
    required this.step,
    required this.key,
    required this.title,
    required this.status,
  });

  factory OnboardingFlowStep.fromJson(Map<String, dynamic> json) {
    return OnboardingFlowStep(
      step: json['step'] as int,
      key: json['key'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'step': step,
      'key': key,
      'title': title,
      'status': status,
    };
  }

  OnboardingFlowStep copyWith({
    int? step,
    String? key,
    String? title,
    String? status,
  }) {
    return OnboardingFlowStep(
      step: step ?? this.step,
      key: key ?? this.key,
      title: title ?? this.title,
      status: status ?? this.status,
    );
  }
}

class OnboardingFlow {
  final int currentStep;
  final bool isVerified;
  final List<OnboardingFlowStep> steps;

  OnboardingFlow({
    required this.currentStep,
    required this.isVerified,
    required this.steps,
  });

  factory OnboardingFlow.fromJson(Map<String, dynamic> json) {
    final stepsList = (json['steps'] as List<dynamic>? ?? <dynamic>[])
        .map((s) => OnboardingFlowStep.fromJson(s as Map<String, dynamic>))
        .toList();
    return OnboardingFlow(
      currentStep: json['currentStep'] as int? ?? 1,
      isVerified: json['isVerified'] as bool? ?? false,
      steps: stepsList,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentStep': currentStep,
      'isVerified': isVerified,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  OnboardingFlow copyWith({
    int? currentStep,
    bool? isVerified,
    List<OnboardingFlowStep>? steps,
  }) {
    return OnboardingFlow(
      currentStep: currentStep ?? this.currentStep,
      isVerified: isVerified ?? this.isVerified,
      steps: steps ?? this.steps,
    );
  }
}
