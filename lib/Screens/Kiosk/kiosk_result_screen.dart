import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:clinical_ai_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinical_ai_app/Components/colors.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Models/kiosk_api_models.dart';
import 'package:clinical_ai_app/Screens/Kiosk/kiosk_flow_screen.dart';

class KioskResultScreen extends ConsumerWidget {
  const KioskResultScreen({
    super.key,
    required this.result,
  });

  static const routeName = "/kiosk-result";

  final TicketingResult result;

  void _printModelToConsole(BuildContext context) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(result.toJson());
    debugPrint("==================== TICKETING RESULT MODEL ====================");
    debugPrint(jsonString);
    debugPrint("================================================================");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("TicketingResult model printed to console!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final patient = result.patient;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.opdTicketAndResult),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.terminal),
            tooltip: "Print Model to Console",
            onPressed: () => _printModelToConsole(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.home),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                KioskFlowScreen.routeName,
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppLayout.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Success Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppLayout.space20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppLayout.space12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.checkCheck,
                        color: theme.colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppLayout.space12),
                    Text(
                      result.hospitalName ?? l10n.hospitalOpdTicket,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withAlpha(200),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.ticketRegisteredSuccessfully,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (result.opdDateIst != null) ...[
                      const SizedBox(height: AppLayout.space8),
                      Chip(
                        label: Text(
                          l10n.dateLabel(result.opdDateIst!),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppLayout.space20),

              // 2. Ticket Number Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppLayout.radius16),
                  side: BorderSide(color: theme.dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.space20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.ticketNumber,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                result.ticketNumber ?? "#${result.opdNumber ?? 'N/A'}",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (result.visitType != null)
                                Chip(
                                  label: Text(
                                    result.visitType!.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                ),
                              if (result.opdNumber != null)
                                Text(
                                  "OPD No: ${result.opdNumber}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (result.category?.label != null) ...[
                        const Divider(height: AppLayout.space24),
                        Row(
                          children: [
                            const Icon(LucideIcons.stethoscope, size: 18, color: AppColors.brand),
                            const SizedBox(width: 8),
                            Text(
                              l10n.departmentCategory,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: Text(
                                result.category!.label!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppLayout.space20),

              // 3. Patient Details Card
              if (patient != null)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radius16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.user, color: AppColors.brand, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.patientDetails,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.space16),
                        ResultDetailRow(label: l10n.nameLabel, value: patient.name ?? "N/A"),
                        if (patient.patientId != null)
                          ResultDetailRow(label: l10n.patientIdLabel, value: patient.patientId!),
                        if (patient.phone != null)
                          ResultDetailRow(label: l10n.phoneLabel, value: patient.phone!),
                        if (patient.gender != null || patient.age != null)
                          ResultDetailRow(
                            label: l10n.demographicsLabel,
                            value: "${patient.gender ?? ''}${patient.gender != null && patient.age != null ? ' / ' : ''}${patient.age != null ? '${patient.age} yrs' : ''}",
                          ),
                        if (patient.guardianName != null && patient.guardianName!.isNotEmpty)
                          ResultDetailRow(label: l10n.guardianLabel, value: patient.guardianName!),
                        if (patient.address != null && patient.address!.isNotEmpty)
                          ResultDetailRow(label: l10n.addressLabel, value: patient.address!),
                        if (patient.caste != null && patient.caste!.isNotEmpty)
                          ResultDetailRow(label: l10n.categoryCasteLabel, value: patient.caste!),
                      ],
                    ),
                  ),
                ),

              if (patient != null) const SizedBox(height: AppLayout.space20),

              // 4. Clinical Summary Card
              if (result.summary != null && result.summary!.isNotEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radius16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.fileText, color: AppColors.brand, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.consultationSummary,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.space12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppLayout.space12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                            borderRadius: BorderRadius.circular(AppLayout.radius8),
                          ),
                          child: Text(
                            result.summary!,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (result.summary != null && result.summary!.isNotEmpty)
                const SizedBox(height: AppLayout.space20),

              // 5. Clinical Flags Card (if present)
              if (result.flags.isNotEmpty)
                Card(
                  elevation: 0,
                  color: AppColors.error.withAlpha(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radius16),
                    side: BorderSide(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppLayout.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.clinicalAlertsAndFlags,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppLayout.space12),
                        ...result.flags.map((flag) => Padding(
                          padding: const EdgeInsets.only(bottom: AppLayout.space8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  flag.flagType ?? "IMPORTANT",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  flag.description ?? "Flag raised",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

              if (result.flags.isNotEmpty) const SizedBox(height: AppLayout.space24),

              // 6. Action Buttons
              CustomButton(
                text: l10n.printModelToConsole,
                onTap: () => _printModelToConsole(context),
              ),
              const SizedBox(height: AppLayout.space12),
              CustomButton(
                text: l10n.finishAndReturnToKioskHome,
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    KioskFlowScreen.routeName,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const ResultDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.space8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: AppLayout.space8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
