import 'package:flutter/material.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_text_field.dart';
import 'package:clinical_ai_app/Custom Widgets/logo_text.dart';
import 'package:clinical_ai_app/Models/kiosk_api_models.dart';
import 'package:clinical_ai_app/Services/Authentication/access_token.dart';
import 'package:clinical_ai_app/Services/Kiosk/kiosk_service.dart';
import 'package:clinical_ai_app/functions.dart';
import 'kiosk_consultation_screen.dart';

class KioskFlowScreen extends StatefulWidget {
  const KioskFlowScreen({super.key});
  static const routeName = "/kiosk-flow";

  @override
  State<KioskFlowScreen> createState() => _KioskFlowScreenState();
}

class _KioskFlowScreenState extends State<KioskFlowScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // State
  String? _hospitalId;
  String? _slug;
  KioskConfig? _config;
  String? _kioskToken;

  // Step: 'pin' | 'form'
  String _step = 'loading';

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
    _initKiosk();
  }

  Future<void> _initKiosk() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AccessTokenService.getToken();
      if (token == null) {
        throw Exception("No authentication token found. Please log in again.");
      }

      final jwtPayload = decodeJwt(token);
      _hospitalId = jwtPayload['hospital_id']?.toString();

      if (_hospitalId == null || _hospitalId!.isEmpty) {
        throw Exception("Hospital ID not found in user session.");
      }

      // 1. Fetch Hospital Details to get slug
      final hospitalDetails = await KioskService.getHospitalDetails(hospitalId: _hospitalId!);
      _slug = hospitalDetails.slug;

      if (_slug == null || _slug!.isEmpty) {
        throw Exception("Hospital slug not found.");
      }

      // 2. Fetch Kiosk Config
      _config = await KioskService.getKioskConfig(slug: _slug!);

      // Decide next step
      if (_config?.hasKioskPin == true) {
        setState(() {
          _step = 'pin';
          _isLoading = false;
        });
      } else {
        _kioskToken = token;
        setState(() {
          _step = 'form';
          _isLoading = false;
        });
      }
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
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await KioskService.unlockKiosk(slug: _slug!, pin: pin);
      _kioskToken = result.accessToken;
      setState(() {
        _step = 'form';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Unlock failed: Invalid PIN or network error.";
        _isLoading = false;
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
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionInit = await KioskService.startPatientSession(
        slug: _slug!,
        phone: phone,
        language: _language,
        visitType: _visitType,
        gender: _gender,
        kioskToken: _kioskToken ?? '',
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KioskConsultationScreen(
            slug: _slug!,
            sessionId: sessionInit.sessionId,
            kioskToken: _kioskToken ?? '',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to start session: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kiosk Ticketing Flow"),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      const LogoAndText(width: 200),
                      const SizedBox(height: AppLayout.space24),

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
                      else if (_step == 'pin')
                        _buildPinUnlockView()
                      else if (_step == 'form')
                        _buildPatientFormView(),
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

  Widget _buildPinUnlockView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Unlock Kiosk",
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppLayout.space8),
        const Text(
          "Enter the 6-digit physical kiosk PIN to begin.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppLayout.space24),
        CustomTextField(
          fieldName: "Kiosk PIN",
          controller: _pinController,
          hintText: "Enter Kiosk PIN",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppLayout.space24),
        CustomButton(
          text: "Unlock Kiosk",
          onTap: _unlockKiosk,
        ),
      ],
    );
  }

  Widget _buildPatientFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Patient Check-In",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppLayout.space16),
        CustomTextField(
          fieldName: "Patient Phone Number",
          controller: _phoneController,
          hintText: "Enter phone number",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppLayout.space16),
        DropdownButtonFormField<String>(
          initialValue: _language,
          decoration: const InputDecoration(labelText: "Preferred Language"),
          items: const [
            DropdownMenuItem(value: 'hi', child: Text('Hindi (HI)')),
            DropdownMenuItem(value: 'en', child: Text('English (EN)')),
            DropdownMenuItem(value: 'mr', child: Text('Marathi (MR)')),
            DropdownMenuItem(value: 'gu', child: Text('Gujarati (GU)')),
          ],
          onChanged: (val) => setState(() => _language = val ?? 'hi'),
        ),
        const SizedBox(height: AppLayout.space16),
        DropdownButtonFormField<String>(
          initialValue: _visitType,
          decoration: const InputDecoration(labelText: "Visit Type"),
          items: const [
            DropdownMenuItem(value: 'opd', child: Text('OPD')),
            DropdownMenuItem(value: 'ipd', child: Text('IPD')),
          ],
          onChanged: (val) => setState(() => _visitType = val ?? 'opd'),
        ),
        const SizedBox(height: AppLayout.space16),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: const InputDecoration(labelText: "Gender"),
          items: const [
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (val) => setState(() => _gender = val ?? 'female'),
        ),
        const SizedBox(height: AppLayout.space32),
        CustomButton(
          text: "Start Consultation Session",
          onTap: _startSession,
        ),
      ],
    );
  }
}
