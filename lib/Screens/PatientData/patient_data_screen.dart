import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:flutter/material.dart';
import 'package:clinical_ai_app/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../Models/patient_response_history_model.dart';
import '../../Components/colors.dart';
import 'patient_history_view.dart';
import '../Consultation/new_consultation_screen.dart';
import '../Consultation/new_cabin_consultation_screen.dart';
import '../Consultation/audio_recording_screen.dart';

class PatientDataScreen extends StatefulWidget {
  const PatientDataScreen({super.key, required this.patientHistory});
  static const routeName = "/patient-data";
  final PatientHistoryResponse patientHistory;

  @override
  State<PatientDataScreen> createState() => _PatientDataScreenState();
}

class _PatientDataScreenState extends State<PatientDataScreen> {
  late PatientHistoryResponse history;

  @override
  void initState() {
    super.initState();
    history = widget.patientHistory;
  }

  @override
  void didUpdateWidget(PatientDataScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patientHistory != oldWidget.patientHistory) {
      setState(() {
        history = widget.patientHistory;
      });
    }
  }

  void _showConsultationTypeDialog() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final primaryIconColor = isDark ? Colors.white : theme.colorScheme.primary;
    final warningIconColor = isDark ? Colors.white : AppColors.warning;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radius16)),
        title: Text(l10n.startNewSession),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppLayout.space8),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.primary.withAlpha(120) : theme.colorScheme.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppLayout.radius8),
                ),
                child: Icon(LucideIcons.stethoscope, color: primaryIconColor, size: AppLayout.iconMedium),
              ),
              title: Text(l10n.medicalConsultation),
              subtitle: Text(l10n.standardAiAssistedHistory),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewConsultationScreen(
                      patientName: history.patient.name,
                      patientAge: history.patient.age,
                      patientGender: history.patient.gender ?? "",
                      patientId: history.patient.patientId,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppLayout.space8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.warning.withAlpha(120) : AppColors.warning.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppLayout.radius8),
                ),
                child: Icon(LucideIcons.monitor, color: warningIconColor, size: AppLayout.iconMedium),
              ),
              title: Text(l10n.cabinFlow),
              subtitle: Text(l10n.doctorLedLiveConsultation),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewCabinConsultationScreen(
                      patientId: history.patient.patientId,
                      patientName: history.patient.name,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppLayout.space8),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.secondary.withAlpha(120) : theme.colorScheme.secondary.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppLayout.radius8),
                ),
                child: Icon(LucideIcons.mic, color: primaryIconColor, size: AppLayout.iconMedium),
              ),
              title: Text(l10n.audioRecording),
              subtitle: Text(l10n.recordAudioSession),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioRecordingScreen(
                      patientId: history.patient.patientId,
                      patientName: history.patient.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showConsultationTypeDialog,
        child: const Icon(LucideIcons.clipboardPlus),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back),
                  Text(
                    "${l10n.patients}  /  ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width / 3,
              child: Text(
                history.patient.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppLayout.space16, vertical: 10),
            child: Image.asset("assets/kuvaka_logo.png"),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppLayout.space16),
          child: PatientClinicalHistoryView(
            patientHistory: history,
            onHistoryUpdated: () {
              // Handle any state sync if needed
            },
          ),
        ),
      ),
    );
  }
}
