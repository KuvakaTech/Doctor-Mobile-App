import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @welcomeToKuvaka.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kuvaka'**
  String get welcomeToKuvaka;

  /// No description provided for @selectModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select your mode to proceed with the consultation or management.'**
  String get selectModeDescription;

  /// No description provided for @homeScreenConsultation.
  ///
  /// In en, this message translates to:
  /// **'Home Screen / Consultation'**
  String get homeScreenConsultation;

  /// No description provided for @kioskTicketingFlow.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Ticketing Flow'**
  String get kioskTicketingFlow;

  /// No description provided for @loadingKiosk.
  ///
  /// In en, this message translates to:
  /// **'Loading Kiosk...'**
  String get loadingKiosk;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get signingOut;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Do you want to Sign Out?'**
  String get confirmSignOut;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smarter histories.\nBetter outcomes.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubhead.
  ///
  /// In en, this message translates to:
  /// **'AI-powered medical history taking that helps you diagnose with confidence and document without the burden.'**
  String get welcomeSubhead;

  /// No description provided for @featureHistory.
  ///
  /// In en, this message translates to:
  /// **'Structured patient history in under 5 minutes'**
  String get featureHistory;

  /// No description provided for @featureDiagnoses.
  ///
  /// In en, this message translates to:
  /// **'AI-generated differential diagnoses'**
  String get featureDiagnoses;

  /// No description provided for @featureSoap.
  ///
  /// In en, this message translates to:
  /// **'Instant SOAP note documentation'**
  String get featureSoap;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get loginTitle;

  /// No description provided for @signInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue.'**
  String get signInDescription;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'doctor@hospital.com'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **' Create an Account'**
  String get createAnAccount;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccountTitle;

  /// No description provided for @createAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Start taking smarter clinical histories today.'**
  String get createAccountDescription;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Priya Sharma'**
  String get nameHint;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating Account...'**
  String get creatingAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an Account?'**
  String get alreadyHaveAccount;

  /// No description provided for @unlockKiosk.
  ///
  /// In en, this message translates to:
  /// **'Unlock Kiosk'**
  String get unlockKiosk;

  /// No description provided for @unlockKioskDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit physical kiosk PIN to begin.'**
  String get unlockKioskDescription;

  /// No description provided for @unlockingKiosk.
  ///
  /// In en, this message translates to:
  /// **'Unlocking Kiosk...'**
  String get unlockingKiosk;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clear;

  /// No description provided for @patientCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Patient Check-In'**
  String get patientCheckIn;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of 4'**
  String stepProgress(int step);

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get enterPhoneNumber;

  /// No description provided for @phoneDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this phone number to associate your consultation ticket.'**
  String get phoneDescription;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +91 98765 43210'**
  String get phoneHint;

  /// No description provided for @selectVisitType.
  ///
  /// In en, this message translates to:
  /// **'Select Visit Type'**
  String get selectVisitType;

  /// No description provided for @visitTypeDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you visiting for Outpatient (OPD) or Inpatient (IPD) consultation?'**
  String get visitTypeDescription;

  /// No description provided for @visitType.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get visitType;

  /// No description provided for @opdOutpatient.
  ///
  /// In en, this message translates to:
  /// **'OPD (Outpatient)'**
  String get opdOutpatient;

  /// No description provided for @ipdInpatient.
  ///
  /// In en, this message translates to:
  /// **'IPD (Inpatient)'**
  String get ipdInpatient;

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Preferred Language'**
  String get selectPreferredLanguage;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you prefer for the AI voice assistant.'**
  String get languageDescription;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi (HI)'**
  String get hindi;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English (EN)'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi (MR)'**
  String get marathi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati (GU)'**
  String get gujarati;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @genderDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select patient gender.'**
  String get genderDescription;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startConsultationSession.
  ///
  /// In en, this message translates to:
  /// **'Start Consultation Session'**
  String get startConsultationSession;

  /// No description provided for @startingSession.
  ///
  /// In en, this message translates to:
  /// **'Starting Session...'**
  String get startingSession;

  /// No description provided for @backToPreviousStep.
  ///
  /// In en, this message translates to:
  /// **'Back to previous step'**
  String get backToPreviousStep;

  /// No description provided for @enterValidPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid PIN.'**
  String get enterValidPin;

  /// No description provided for @enterPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number.'**
  String get enterPhoneError;

  /// No description provided for @unlockFailedError.
  ///
  /// In en, this message translates to:
  /// **'Unlock failed: Invalid PIN or network error.'**
  String get unlockFailedError;

  /// No description provided for @kioskConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Consultation ({sessionId})'**
  String kioskConsultationTitle(String sessionId);

  /// No description provided for @aiMedicalAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Medical Agent'**
  String get aiMedicalAgent;

  /// No description provided for @consultationSummaryReady.
  ///
  /// In en, this message translates to:
  /// **'Consultation Summary Ready'**
  String get consultationSummaryReady;

  /// No description provided for @noSummaryProvided.
  ///
  /// In en, this message translates to:
  /// **'No summary provided.'**
  String get noSummaryProvided;

  /// No description provided for @fetchingResult.
  ///
  /// In en, this message translates to:
  /// **'Fetching Result...'**
  String get fetchingResult;

  /// No description provided for @endSessionAndViewResult.
  ///
  /// In en, this message translates to:
  /// **'End Session & View Result'**
  String get endSessionAndViewResult;

  /// No description provided for @opdTicketAndResult.
  ///
  /// In en, this message translates to:
  /// **'OPD Ticket & Result'**
  String get opdTicketAndResult;

  /// No description provided for @printModelToConsole.
  ///
  /// In en, this message translates to:
  /// **'Print Model to Console'**
  String get printModelToConsole;

  /// No description provided for @hospitalOpdTicket.
  ///
  /// In en, this message translates to:
  /// **'Hospital OPD Ticket'**
  String get hospitalOpdTicket;

  /// No description provided for @ticketRegisteredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ticket Registered Successfully'**
  String get ticketRegisteredSuccessfully;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'TICKET NUMBER'**
  String get ticketNumber;

  /// No description provided for @departmentCategory.
  ///
  /// In en, this message translates to:
  /// **'Department / Category: '**
  String get departmentCategory;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @consultationSummary.
  ///
  /// In en, this message translates to:
  /// **'Consultation Summary'**
  String get consultationSummary;

  /// No description provided for @clinicalAlertsAndFlags.
  ///
  /// In en, this message translates to:
  /// **'Clinical Alerts & Flags'**
  String get clinicalAlertsAndFlags;

  /// No description provided for @finishAndReturnToKioskHome.
  ///
  /// In en, this message translates to:
  /// **'Finish & Return to Kiosk Home'**
  String get finishAndReturnToKioskHome;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @patientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient ID'**
  String get patientIdLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @demographicsLabel.
  ///
  /// In en, this message translates to:
  /// **'Demographics'**
  String get demographicsLabel;

  /// No description provided for @guardianLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get guardianLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @categoryCasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Category/Caste'**
  String get categoryCasteLabel;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @managePatientRecords.
  ///
  /// In en, this message translates to:
  /// **'Manage your patient records'**
  String get managePatientRecords;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noPatientRecords.
  ///
  /// In en, this message translates to:
  /// **'No patient records'**
  String get noPatientRecords;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in: {name}'**
  String loggedInAs(String name);

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Do you want to Logout?'**
  String get confirmLogout;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @failedToFetchHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch patient history.'**
  String get failedToFetchHistory;

  /// No description provided for @startNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start New Session'**
  String get startNewSession;

  /// No description provided for @medicalConsultation.
  ///
  /// In en, this message translates to:
  /// **'Medical Consultation'**
  String get medicalConsultation;

  /// No description provided for @standardAiAssistedHistory.
  ///
  /// In en, this message translates to:
  /// **'Standard AI-assisted history taking'**
  String get standardAiAssistedHistory;

  /// No description provided for @cabinFlow.
  ///
  /// In en, this message translates to:
  /// **'Cabin Flow'**
  String get cabinFlow;

  /// No description provided for @doctorLedLiveConsultation.
  ///
  /// In en, this message translates to:
  /// **'Doctor-led live consultation'**
  String get doctorLedLiveConsultation;

  /// No description provided for @audioRecording.
  ///
  /// In en, this message translates to:
  /// **'Audio Recording'**
  String get audioRecording;

  /// No description provided for @recordAudioSession.
  ///
  /// In en, this message translates to:
  /// **'Record audio consultation session'**
  String get recordAudioSession;

  /// No description provided for @consultationHistory.
  ///
  /// In en, this message translates to:
  /// **'Consultation History'**
  String get consultationHistory;

  /// No description provided for @cabinSessions.
  ///
  /// In en, this message translates to:
  /// **'Cabin Sessions'**
  String get cabinSessions;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @cabinTab.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get cabinTab;

  /// No description provided for @noConsultationsYet.
  ///
  /// In en, this message translates to:
  /// **'No consultations yet'**
  String get noConsultationsYet;

  /// No description provided for @startFirstConsultationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start the first one using the button below.'**
  String get startFirstConsultationPrompt;

  /// No description provided for @deleteConsultationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this consultation?'**
  String get deleteConsultationConfirm;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @consultationDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Consultation deleted successfully'**
  String get consultationDeletedSuccess;

  /// No description provided for @deleteCabinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this cabin consultation?'**
  String get deleteCabinConfirm;

  /// No description provided for @cabinDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cabin consultation deleted successfully'**
  String get cabinDeletedSuccess;

  /// No description provided for @deleteSelectedSessionsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected sessions?'**
  String deleteSelectedSessionsConfirm(int count);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// No description provided for @pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get pdfSaved;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {location}'**
  String savedTo(String location);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @audioRecordingTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Recording - {patientName}'**
  String audioRecordingTitle(String patientName);

  /// No description provided for @offlineModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineModeBadge;

  /// No description provided for @onlineModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Online Mode'**
  String get onlineModeBadge;

  /// No description provided for @offlineSyncNotice.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Recording will be saved locally and queued for auto-sync when back online.'**
  String get offlineSyncNotice;

  /// No description provided for @onlineSyncNotice.
  ///
  /// In en, this message translates to:
  /// **'Connected to server. Recording will be processed immediately upon completion.'**
  String get onlineSyncNotice;

  /// No description provided for @readyToRecord.
  ///
  /// In en, this message translates to:
  /// **'Ready to Record'**
  String get readyToRecord;

  /// No description provided for @recordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording Consultation...'**
  String get recordingInProgress;

  /// No description provided for @recordingPaused.
  ///
  /// In en, this message translates to:
  /// **'Recording Paused'**
  String get recordingPaused;

  /// No description provided for @recordingComplete.
  ///
  /// In en, this message translates to:
  /// **'Recording Complete'**
  String get recordingComplete;

  /// No description provided for @tapToStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone button to start recording the consultation session.'**
  String get tapToStartRecording;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @pauseRecording.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseRecording;

  /// No description provided for @resumeRecording.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get stopRecording;

  /// No description provided for @reRecord.
  ///
  /// In en, this message translates to:
  /// **'Re-record'**
  String get reRecord;

  /// No description provided for @uploadConsultationAudio.
  ///
  /// In en, this message translates to:
  /// **'Upload Consultation Audio'**
  String get uploadConsultationAudio;

  /// No description provided for @saveToQueue.
  ///
  /// In en, this message translates to:
  /// **'Save & Queue for Sync'**
  String get saveToQueue;

  /// No description provided for @processingAudio.
  ///
  /// In en, this message translates to:
  /// **'Processing Audio...'**
  String get processingAudio;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
