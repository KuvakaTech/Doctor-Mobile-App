import 'package:clinical_ai_app/Components/layout_constants.dart';
import 'package:clinical_ai_app/Custom%20Widgets/custom_button.dart';
import 'package:clinical_ai_app/Custom%20Widgets/logo_text.dart';
import 'package:clinical_ai_app/Screens/PatientData/home_screen.dart';
import 'package:clinical_ai_app/Screens/Kiosk/kiosk_flow_screen.dart';
import 'package:flutter/material.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});
  static const routeName = "/selection";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  decoration: isTablet ? BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppLayout.panelRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.light ? 15 : 40),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Theme.of(context).dividerColor, width: AppLayout.borderThin),
                  ) : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isTablet ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      LogoAndText(width: isTablet ? 600 : constraints.maxWidth),
                      
                      const SizedBox(height: AppLayout.space32),
                      
                      Text(
                        "Welcome to Kuvaka",
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: isTablet ? 36 : 28,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: AppLayout.space16),
                      
                      Text(
                        "Please select your mode to proceed with the consultation or management.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: isTablet ? 18 : 16,
                          height: 1.5,
                        ),
                        textAlign: isTablet ? TextAlign.center : TextAlign.left,
                      ),
                      
                      const SizedBox(height: AppLayout.space40),
                      
                      CustomButton(
                        text: 'Home Screen / Consultation',
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
                        text: 'Kiosk Ticketing Flow',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            KioskFlowScreen.routeName,
                          );
                        },
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
