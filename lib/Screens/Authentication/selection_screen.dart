import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clinical_ai_app/l10n/app_localizations.dart';
import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_button.dart';
import 'package:clinical_ai_app/Custom Widgets/custom_confirmation_alert.dart';
import 'package:clinical_ai_app/Custom Widgets/logo_text.dart';
import 'package:clinical_ai_app/Screens/PatientData/home_screen.dart';
import 'package:clinical_ai_app/Screens/Kiosk/kiosk_flow_screen.dart';
import 'package:clinical_ai_app/Services/Authentication/access_token.dart';
import 'package:clinical_ai_app/Services/Authentication/navigation_service.dart';
import 'package:clinical_ai_app/Services/Locale/locale_provider.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});
  static const routeName = "/selection";

  void _handleSignOut(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showCustomConfirmationAlert(
      detail: l10n.confirmSignOut,
      confirmText: l10n.signOut,
      loadingText: l10n.signingOut,
      context: context,
      onPressed: () async {
        await AccessTokenService.clear();
        logout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppLayout.space16),
            child: Consumer(
              builder: (context, ref, child) {
                final currentLocale = ref.watch(localeProvider);
                final currentCode = currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode;

                return PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radius12),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.space12,
                      vertical: AppLayout.space6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppLayout.radius20),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: AppLayout.borderThin,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.globe, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          currentCode == 'hi' ? 'हिंदी' : 'English',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                  onSelected: (code) {
                    ref.read(localeProvider.notifier).setLocale(Locale(code));
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'en',
                      child: Text('🇬🇧  English'),
                    ),
                    const PopupMenuItem(
                      value: 'hi',
                      child: Text('🇮🇳  हिंदी (Hindi)'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            double contentWidth = isTablet ? 500 : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppLayout.space40 : AppLayout.space24,
                  vertical: AppLayout.space32,
                ),
                child: Container(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  padding: isTablet ? const EdgeInsets.all(AppLayout.space40) : EdgeInsets.zero,
                  decoration: isTablet
                      ? BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                Theme.of(context).brightness == Brightness.light ? 15 : 40,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: AppLayout.borderThin,
                          ),
                        )
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      LogoAndText(width: isTablet ? 600 : constraints.maxWidth),

                      const SizedBox(height: AppLayout.space32),

                      Text(
                        l10n.welcomeToKuvaka,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: isTablet ? 36 : 28,
                            ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),

                      const SizedBox(height: AppLayout.space16),

                      Text(
                        l10n.selectModeDescription,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: isTablet ? 18 : 16,
                              height: 1.5,
                            ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),

                      const SizedBox(height: AppLayout.space40),

                      CustomButton(
                        text: l10n.homeScreenConsultation,
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            HomeScreen.routeName,
                            (route) => false,
                          );
                        },
                      ),

                      const SizedBox(height: AppLayout.space16),

                      CustomButton(
                        text: l10n.kioskTicketingFlow,
                        loadingText: l10n.loadingKiosk,
                        onTap: () async {
                          try {
                            final initData = await KioskFlowScreen.prepareKioskFlow();
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KioskFlowScreen(
                                  initialStep: initData.step,
                                  slug: initData.slug,
                                  config: initData.config,
                                  kioskToken: initData.kioskToken,
                                ),
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            Navigator.pushNamed(
                              context,
                              KioskFlowScreen.routeName,
                            );
                          }
                        },
                      ),

                      const SizedBox(height: AppLayout.space16),

                      Center(
                        child: TextButton.icon(
                          onPressed: () => _handleSignOut(context),
                          icon: const Icon(LucideIcons.logOut, size: 18),
                          label: Text(l10n.signOut),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            backgroundColor: Colors.white,
                            elevation: 50
                          ),
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
