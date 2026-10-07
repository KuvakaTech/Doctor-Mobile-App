import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Models/kiosk_api_models.dart';
import 'package:clinical_ai_app/Screens/Authentication/selection_screen.dart';
import 'package:clinical_ai_app/Services/Authentication/access_token.dart';
import 'package:clinical_ai_app/Services/Kiosk/kiosk_service.dart';
import 'package:clinical_ai_app/functions.dart';
import 'kiosk_consultation_screen.dart';

class KioskFlowInitData {
  final String step; // 'pin' | 'form'
  final String slug;
  final KioskConfig config;
  final String? kioskToken;

  KioskFlowInitData({
    required this.step,
    required this.slug,
    required this.config,
    this.kioskToken,
  });
}

class KioskFlowScreen extends StatefulWidget {
  const KioskFlowScreen({
    super.key,
    this.initialStep,
    this.slug,
    this.config,
    this.kioskToken,
  });

  static const routeName = "/kiosk-flow";

  final String? initialStep;
  final String? slug;
  final KioskConfig? config;
  final String? kioskToken;

  static Future<KioskFlowInitData> prepareKioskFlow() async {
    final token = await AccessTokenService.getToken();
    if (token == null) {
      throw Exception("No authentication token found. Please log in again.");
    }

    final jwtPayload = decodeJwt(token);
    final hospitalId = jwtPayload['hospital_id']?.toString();

    if (hospitalId == null || hospitalId.isEmpty) {
      throw Exception("Hospital ID not found in user session.");
    }

    final hospitalDetails = await KioskService.getHospitalDetails(hospitalId: hospitalId);
    final slug = hospitalDetails.slug;

    if (slug == null || slug.isEmpty) {
      throw Exception("Hospital slug not found.");
    }

    final config = await KioskService.getKioskConfig(slug: slug);
    final existingKioskToken = await AccessTokenService.getKioskToken();

    if (existingKioskToken != null && existingKioskToken.isNotEmpty) {
      final isValid = await KioskService.verifyKioskToken(
        slug: slug,
        kioskToken: existingKioskToken,
      );

      if (isValid) {
        return KioskFlowInitData(
          step: 'form',
          slug: slug,
          config: config,
          kioskToken: existingKioskToken,
        );
      } else {
        await AccessTokenService.deleteKioskToken();
      }
    }

    if (config.hasKioskPin == true) {
      return KioskFlowInitData(
        step: 'pin',
        slug: slug,
        config: config,
      );
    } else {
      await AccessTokenService.saveKioskToken(token);
      return KioskFlowInitData(
        step: 'form',
        slug: slug,
        config: config,
        kioskToken: token,
      );
    }
  }

  @override
  State<KioskFlowScreen> createState() => _KioskFlowScreenState();
}

class _KioskFlowScreenState extends State<KioskFlowScreen> {
  late bool _isLoading;
  String? _errorMessage;

  // State
  String? _slug;
  String? _kioskToken;

  // Step: 'pin' | 'form'
  late String _step;

  // Multi-step form wizard step (0: Phone, 1: Visit Type, 2: Language, 3: Gender)
  int _formStep = 0;

  // PIN Controller
  final TextEditingController _pinController = TextEditingController();

  // Patient Form Controllers
  final TextEditingController _phoneController = TextEditingController();
  String _language = 'hi';
  String _visitType = 'opd';
  String _gender = 'female';

  @override
  void initState() {
    super.initState();
    if (widget.initialStep != null) {
      _isLoading = false;
      _step = widget.initialStep!;
      _slug = widget.slug;
      _kioskToken = widget.kioskToken;
    } else {
      _isLoading = true;
      _step = 'loading';
      _initKiosk();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _initKiosk() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final initData = await KioskFlowScreen.prepareKioskFlow();
      _slug = initData.slug;
      _kioskToken = initData.kioskToken;
      setState(() {
        _step = initData.step;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockKiosk() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = "Please enter a valid PIN.");
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await KioskService.unlockKiosk(slug: _slug!, pin: pin);
      await AccessTokenService.saveKioskToken(result.accessToken);
      _kioskToken = result.accessToken;
      setState(() {
        _step = 'form';
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Unlock failed: Invalid PIN or network error.";
      });
    }
  }

  Future<void> _startSession() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = "Please enter phone number.");
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final kioskToken = await AccessTokenService.getKioskToken() ?? _kioskToken ?? '';

      final sessionInit = await KioskService.startPatientSession(
        slug: _slug!,
        phone: phone,
        language: _language,
        visitType: _visitType,
        gender: _gender,
        kioskToken: kioskToken,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KioskConsultationScreen(
            slug: _slug!,
            sessionId: sessionInit.sessionId,
            kioskToken: kioskToken,
          ),
        ),
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains("401") || errorStr.contains("unauthorized")) {
        await AccessTokenService.deleteKioskToken();
        _kioskToken = null;
        setState(() {
          _step = 'pin';
          _errorMessage = "Kiosk token expired or unauthorized. Please re-enter PIN to unlock.";
        });
      } else {
        setState(() {
          _errorMessage = "Failed to start session: $e";
        });
      }
    }
  }

  void _handleNumpadKey(String key) {
    if (key == 'clear') {
      setState(() {
        _pinController.clear();
      });
    } else if (key == 'backspace') {
      if (_pinController.text.isNotEmpty) {
        setState(() {
          _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
        });
      }
    } else {
      if (_pinController.text.length < 6) {
        setState(() {
          _pinController.text += key;
        });
      }
    }
  }

  void _handleNextFormStep() {
    if (_formStep == 0) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() => _errorMessage = "Please enter phone number.");
        return;
      }
    }
    setState(() {
      _errorMessage = null;
      _formStep++;
    });
  }

  void _handlePreviousFormStep() {
    setState(() {
      _errorMessage = null;
      _formStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kiosk Ticketing Flow"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.home),
          tooltip: "Return to Mode Selection",
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              SelectionScreen.routeName,
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            double contentWidth = isTablet ? 550 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppLayout.space40 : AppLayout.space24,
                  vertical: AppLayout.space24,
                ),
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  padding: isTablet ? const EdgeInsets.all(AppLayout.space40) : EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppLayout.space12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(AppLayout.radius8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        const SizedBox(height: AppLayout.space16),
                      ],

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Container(
                          padding: isTablet
                              ? const EdgeInsets.all(AppLayout.space32)
                              : const EdgeInsets.all(AppLayout.space24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                              width: AppLayout.borderThin,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  Theme.of(context).brightness == Brightness.light ? 12 : 40,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _step == 'pin'
                              ? KioskPinUnlockView(
                                  pin: _pinController.text,
                                  errorMessage: _errorMessage,
                                  onUnlock: _unlockKiosk,
                                  onNumpadKeyTap: _handleNumpadKey,
                                )
                              : KioskPatientFormView(
                                  formStep: _formStep,
                                  phoneController: _phoneController,
                                  language: _language,
                                  visitType: _visitType,
                                  gender: _gender,
                                  onLanguageChanged: (val) => setState(() => _language = val),
                                  onVisitTypeChanged: (val) => setState(() => _visitType = val),
                                  onGenderChanged: (val) => setState(() => _gender = val),
                                  onNextStep: _handleNextFormStep,
                                  onPreviousStep: _handlePreviousFormStep,
                                  onStartSession: _startSession,
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class KioskPinUnlockView extends StatelessWidget {
  final String pin;
  final String? errorMessage;
  final VoidCallback onUnlock;
  final Function(String key) onNumpadKeyTap;

  const KioskPinUnlockView({
    super.key,
    required this.pin,
    this.errorMessage,
    required this.onUnlock,
    required this.onNumpadKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Unlock Kiosk",
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppLayout.space8),
        Text(
          "Enter the 6-digit physical kiosk PIN to begin.",
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppLayout.space24),

        // PIN Display Dots Indicator
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.space24,
              vertical: AppLayout.space16,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppLayout.radius12),
              border: Border.all(
                color: errorMessage != null ? AppColors.error : theme.dividerColor,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool isFilled = index < pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppLayout.space8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.brand : theme.dividerColor,
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: AppLayout.space24),

        // On-Screen Numpad
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              children: [
                KioskNumpadRow(keys: const ['1', '2', '3'], onKeyTap: onNumpadKeyTap),
                const SizedBox(height: AppLayout.space12),
                KioskNumpadRow(keys: const ['4', '5', '6'], onKeyTap: onNumpadKeyTap),
                const SizedBox(height: AppLayout.space12),
                KioskNumpadRow(keys: const ['7', '8', '9'], onKeyTap: onNumpadKeyTap),
                const SizedBox(height: AppLayout.space12),
                KioskNumpadRow(keys: const ['clear', '0', 'backspace'], onKeyTap: onNumpadKeyTap),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppLayout.space24),

        CustomButton(
          text: "Unlock Kiosk",
          loadingText: "Unlocking Kiosk...",
          onTap: onUnlock,
        ),
      ],
    );
  }
}

class KioskNumpadRow extends StatelessWidget {
  final List<String> keys;
  final Function(String key) onKeyTap;

  const KioskNumpadRow({
    super.key,
    required this.keys,
    required this.onKeyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'clear') {
          return KioskNumpadButton(
            onTap: () => onKeyTap('clear'),
            child: Text(
              "CLEAR",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
          );
        } else if (key == 'backspace') {
          return KioskNumpadButton(
            onTap: () => onKeyTap('backspace'),
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
          );
        } else {
          return KioskNumpadButton(
            onTap: () => onKeyTap(key),
            child: Text(
              key,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}

class KioskNumpadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const KioskNumpadButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselectedBg = theme.scaffoldBackgroundColor;
    return Material(
      color: unselectedBg,
      borderRadius: BorderRadius.circular(AppLayout.radius12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        child: Container(
          width: 76,
          height: 60,
          decoration: BoxDecoration(
            color: unselectedBg,
            borderRadius: BorderRadius.circular(AppLayout.radius12),
            border: Border.all(color: theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class KioskPatientFormView extends StatelessWidget {
  final int formStep;
  final TextEditingController phoneController;
  final String language;
  final String visitType;
  final String gender;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onVisitTypeChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onNextStep;
  final VoidCallback onPreviousStep;
  final CustomButtonCallback onStartSession;

  const KioskPatientFormView({
    super.key,
    required this.formStep,
    required this.phoneController,
    required this.language,
    required this.visitType,
    required this.gender,
    required this.onLanguageChanged,
    required this.onVisitTypeChanged,
    required this.onGenderChanged,
    required this.onNextStep,
    required this.onPreviousStep,
    required this.onStartSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = (formStep + 1) / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Step Badge Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Patient Check-In",
              style: theme.textTheme.headlineMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.space10,
                vertical: AppLayout.space4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppLayout.radius12),
              ),
              child: Text(
                "Step ${formStep + 1} of 4",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppLayout.space12),

        // Top Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.radius8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppLayout.space8,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),

        const SizedBox(height: AppLayout.space24),

        // Step Content View with Smooth Animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey<int>(formStep),
            child: KioskFormStepContent(
              formStep: formStep,
              phoneController: phoneController,
              language: language,
              visitType: visitType,
              gender: gender,
              onLanguageChanged: onLanguageChanged,
              onVisitTypeChanged: onVisitTypeChanged,
              onGenderChanged: onGenderChanged,
            ),
          ),
        ),

        const SizedBox(height: AppLayout.space32),

        // Action Buttons
        if (formStep < 3)
          CustomButton(
            text: "Next",
            onTap: onNextStep,
          )
        else
          CustomButton(
            text: "Start Consultation Session",
            loadingText: "Starting Session...",
            onTap: onStartSession,
          ),

        if (formStep > 0) ...[
          const SizedBox(height: AppLayout.space12),
          TextButton.icon(
            onPressed: onPreviousStep,
            icon: const Icon(Icons.arrow_back, size: AppLayout.iconSmall + 2),
            label: const Text("Back to previous step"),
          ),
        ],
      ],
    );
  }
}

class KioskFormStepContent extends StatelessWidget {
  final int formStep;
  final TextEditingController phoneController;
  final String language;
  final String visitType;
  final String gender;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onVisitTypeChanged;
  final ValueChanged<String> onGenderChanged;

  const KioskFormStepContent({
    super.key,
    required this.formStep,
    required this.phoneController,
    required this.language,
    required this.visitType,
    required this.gender,
    required this.onLanguageChanged,
    required this.onVisitTypeChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (formStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          key: const ValueKey(0),
          children: [
            Text(
              "Enter Phone Number",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLayout.space8),
            Text(
              "We'll use this phone number to associate your consultation ticket.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.space20),
            const _FieldLabel(label: "Phone Number", required: true),
            const SizedBox(height: AppLayout.space8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                fillColor: theme.scaffoldBackgroundColor,
                hintText: "e.g. +91 98765 43210",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.space16,
                  vertical: AppLayout.space12 + 2,
                ),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          key: const ValueKey(1),
          children: [
            Text(
              "Select Visit Type",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLayout.space8),
            Text(
              "Are you visiting for Outpatient (OPD) or Inpatient (IPD) consultation?",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.space20),
            const _FieldLabel(label: "Visit Type", required: true),
            const SizedBox(height: AppLayout.space8),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: SelectableOptionButton(
                      label: "OPD (Outpatient)",
                      selected: visitType == 'opd',
                      onTap: () => onVisitTypeChanged('opd'),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space12),
                  Expanded(
                    child: SelectableOptionButton(
                      label: "IPD (Inpatient)",
                      selected: visitType == 'ipd',
                      onTap: () => onVisitTypeChanged('ipd'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          key: const ValueKey(2),
          children: [
            Text(
              "Select Preferred Language",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLayout.space8),
            Text(
              "Choose the language you prefer for the AI voice assistant.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.space20),
            const _FieldLabel(label: "Preferred Language", required: true),
            const SizedBox(height: AppLayout.space8),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SelectableOptionButton(
                        label: "Hindi (HI)",
                        selected: language == 'hi',
                        onTap: () => onLanguageChanged('hi'),
                      ),
                    ),
                    const SizedBox(width: AppLayout.space12),
                    Expanded(
                      child: SelectableOptionButton(
                        label: "English (EN)",
                        selected: language == 'en',
                        onTap: () => onLanguageChanged('en'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppLayout.space12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableOptionButton(
                        label: "Marathi (MR)",
                        selected: language == 'mr',
                        onTap: () => onLanguageChanged('mr'),
                      ),
                    ),
                    const SizedBox(width: AppLayout.space12),
                    Expanded(
                      child: SelectableOptionButton(
                        label: "Gujarati (GU)",
                        selected: language == 'gu',
                        onTap: () => onLanguageChanged('gu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

      case 3:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          key: const ValueKey(3),
          children: [
            Text(
              "Select Gender",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppLayout.space8),
            Text(
              "Please select patient gender.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppLayout.space20),
            const _FieldLabel(label: "Gender", required: true),
            const SizedBox(height: AppLayout.space8),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: SelectableOptionButton(
                      label: "Female",
                      selected: gender == 'female',
                      onTap: () => onGenderChanged('female'),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space12),
                  Expanded(
                    child: SelectableOptionButton(
                      label: "Male",
                      selected: gender == 'male',
                      onTap: () => onGenderChanged('male'),
                    ),
                  ),
                  const SizedBox(width: AppLayout.space12),
                  Expanded(
                    child: SelectableOptionButton(
                      label: "Other",
                      selected: gender == 'other',
                      onTap: () => onGenderChanged('other'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class SelectableOptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectableOptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBg = theme.colorScheme.primary;
    final onPrimaryFg = theme.colorScheme.onPrimary;
    final unselectedBg = theme.scaffoldBackgroundColor;

    return Material(
      color: selected ? primaryBg : unselectedBg,
      borderRadius: BorderRadius.circular(AppLayout.radius12),
      child: InkWell(
        onTap: onTap,
        splashColor: primaryBg.withAlpha(50),
        borderRadius: BorderRadius.circular(AppLayout.radius12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: AppLayout.space12,
            horizontal: AppLayout.space8,
          ),
          decoration: BoxDecoration(
            color: selected ? primaryBg : unselectedBg,
            borderRadius: BorderRadius.circular(AppLayout.radius12),
            border: Border.all(
              color: selected ? primaryBg : theme.dividerColor,
              width: selected ? AppLayout.borderThick : AppLayout.borderMedium,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? onPrimaryFg : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({
    required this.label,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color?.withAlpha(204),
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: label.toUpperCase()),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
