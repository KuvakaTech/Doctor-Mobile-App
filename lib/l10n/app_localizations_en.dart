// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeToKuvaka => 'Welcome to Kuvaka';

  @override
  String get selectModeDescription =>
      'Please select your mode to proceed with the consultation or management.';

  @override
  String get homeScreenConsultation => 'Home Screen / Consultation';

  @override
  String get kioskTicketingFlow => 'Kiosk Ticketing Flow';

  @override
  String get loadingKiosk => 'Loading Kiosk...';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signingOut => 'Signing out...';

  @override
  String get confirmSignOut => 'Do you want to Sign Out?';

  @override
  String get welcomeTitle => 'Smarter histories.\nBetter outcomes.';

  @override
  String get welcomeSubhead =>
      'AI-powered medical history taking that helps you diagnose with confidence and document without the burden.';

  @override
  String get featureHistory => 'Structured patient history in under 5 minutes';

  @override
  String get featureDiagnoses => 'AI-generated differential diagnoses';

  @override
  String get featureSoap => 'Instant SOAP note documentation';

  @override
  String get getStarted => 'Get Started';

  @override
  String get loginTitle => 'Welcome back.';

  @override
  String get signInDescription => 'Sign in to your account to continue.';

  @override
  String get signIn => 'Sign in';

  @override
  String get emailHint => 'doctor@hospital.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get newHere => 'New here?';

  @override
  String get createAnAccount => ' Create an Account';

  @override
  String get createAccountTitle => 'Create Your Account';

  @override
  String get createAccountDescription =>
      'Start taking smarter clinical histories today.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get nameHint => 'Dr. Priya Sharma';

  @override
  String get creatingAccount => 'Creating Account...';

  @override
  String get alreadyHaveAccount => 'Already have an Account?';

  @override
  String get unlockKiosk => 'Unlock Kiosk';

  @override
  String get unlockKioskDescription =>
      'Enter the 6-digit physical kiosk PIN to begin.';

  @override
  String get unlockingKiosk => 'Unlocking Kiosk...';

  @override
  String get clear => 'CLEAR';

  @override
  String get patientCheckIn => 'Patient Check-In';

  @override
  String stepProgress(int step) {
    return 'Step $step of 4';
  }

  @override
  String get enterPhoneNumber => 'Enter Phone Number';

  @override
  String get phoneDescription =>
      'We\'ll use this phone number to associate your consultation ticket.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => 'e.g. +91 98765 43210';

  @override
  String get selectVisitType => 'Select Visit Type';

  @override
  String get visitTypeDescription =>
      'Are you visiting for Outpatient (OPD) or Inpatient (IPD) consultation?';

  @override
  String get visitType => 'Visit Type';

  @override
  String get opdOutpatient => 'OPD (Outpatient)';

  @override
  String get ipdInpatient => 'IPD (Inpatient)';

  @override
  String get selectPreferredLanguage => 'Select Preferred Language';

  @override
  String get languageDescription =>
      'Choose the language you prefer for the AI voice assistant.';

  @override
  String get preferredLanguage => 'Preferred Language';

  @override
  String get hindi => 'Hindi (HI)';

  @override
  String get english => 'English (EN)';

  @override
  String get marathi => 'Marathi (MR)';

  @override
  String get gujarati => 'Gujarati (GU)';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get genderDescription => 'Please select patient gender.';

  @override
  String get gender => 'Gender';

  @override
  String get female => 'Female';

  @override
  String get male => 'Male';

  @override
  String get other => 'Other';

  @override
  String get next => 'Next';

  @override
  String get startConsultationSession => 'Start Consultation Session';

  @override
  String get startingSession => 'Starting Session...';

  @override
  String get backToPreviousStep => 'Back to previous step';

  @override
  String get enterValidPin => 'Please enter a valid PIN.';

  @override
  String get enterPhoneError => 'Please enter phone number.';

  @override
  String get unlockFailedError =>
      'Unlock failed: Invalid PIN or network error.';

  @override
  String kioskConsultationTitle(String sessionId) {
    return 'Kiosk Consultation ($sessionId)';
  }

  @override
  String get aiMedicalAgent => 'AI Medical Agent';

  @override
  String get consultationSummaryReady => 'Consultation Summary Ready';

  @override
  String get noSummaryProvided => 'No summary provided.';

  @override
  String get fetchingResult => 'Fetching Result...';

  @override
  String get endSessionAndViewResult => 'End Session & View Result';

  @override
  String get opdTicketAndResult => 'OPD Ticket & Result';

  @override
  String get printModelToConsole => 'Print Model to Console';

  @override
  String get hospitalOpdTicket => 'Hospital OPD Ticket';

  @override
  String get ticketRegisteredSuccessfully => 'Ticket Registered Successfully';

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get ticketNumber => 'TICKET NUMBER';

  @override
  String get departmentCategory => 'Department / Category: ';

  @override
  String get patientDetails => 'Patient Details';

  @override
  String get consultationSummary => 'Consultation Summary';

  @override
  String get clinicalAlertsAndFlags => 'Clinical Alerts & Flags';

  @override
  String get finishAndReturnToKioskHome => 'Finish & Return to Kiosk Home';

  @override
  String get nameLabel => 'Name';

  @override
  String get patientIdLabel => 'Patient ID';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get demographicsLabel => 'Demographics';

  @override
  String get guardianLabel => 'Guardian';

  @override
  String get addressLabel => 'Address';

  @override
  String get categoryCasteLabel => 'Category/Caste';

  @override
  String get patients => 'Patients';

  @override
  String get managePatientRecords => 'Manage your patient records';

  @override
  String get searchHint => 'Search...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noPatientRecords => 'No patient records';

  @override
  String loggedInAs(String name) {
    return 'Logged in: $name';
  }

  @override
  String get confirmLogout => 'Do you want to Logout?';

  @override
  String get logout => 'Logout';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get failedToFetchHistory => 'Failed to fetch patient history.';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get medicalConsultation => 'Medical Consultation';

  @override
  String get standardAiAssistedHistory => 'Standard AI-assisted history taking';

  @override
  String get cabinFlow => 'Cabin Flow';

  @override
  String get doctorLedLiveConsultation => 'Doctor-led live consultation';

  @override
  String get audioRecording => 'Audio Recording';

  @override
  String get recordAudioSession => 'Record audio consultation session';

  @override
  String get consultationHistory => 'Consultation History';

  @override
  String get cabinSessions => 'Cabin Sessions';

  @override
  String get historyTab => 'History';

  @override
  String get cabinTab => 'Cabin';

  @override
  String get noConsultationsYet => 'No consultations yet';

  @override
  String get startFirstConsultationPrompt =>
      'Start the first one using the button below.';

  @override
  String get deleteConsultationConfirm =>
      'Do you want to delete this consultation?';

  @override
  String get deleting => 'Deleting...';

  @override
  String get consultationDeletedSuccess => 'Consultation deleted successfully';

  @override
  String get deleteCabinConfirm =>
      'Do you want to delete this cabin consultation?';

  @override
  String get cabinDeletedSuccess => 'Cabin consultation deleted successfully';

  @override
  String deleteSelectedSessionsConfirm(int count) {
    return 'Delete $count selected sessions?';
  }

  @override
  String selectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get pdfSaved => 'PDF saved';

  @override
  String savedTo(String location) {
    return 'Saved to: $location';
  }

  @override
  String get open => 'OPEN';

  @override
  String audioRecordingTitle(String patientName) {
    return 'Audio Recording - $patientName';
  }

  @override
  String get offlineModeBadge => 'Offline Mode';

  @override
  String get onlineModeBadge => 'Online Mode';

  @override
  String get offlineSyncNotice =>
      'No internet connection. Recording will be saved locally and queued for auto-sync when back online.';

  @override
  String get onlineSyncNotice =>
      'Connected to server. Recording will be processed immediately upon completion.';

  @override
  String get readyToRecord => 'Ready to Record';

  @override
  String get recordingInProgress => 'Recording Consultation...';

  @override
  String get recordingPaused => 'Recording Paused';

  @override
  String get recordingComplete => 'Recording Complete';

  @override
  String get tapToStartRecording =>
      'Tap the microphone button to start recording the consultation session.';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get pauseRecording => 'Pause';

  @override
  String get resumeRecording => 'Resume';

  @override
  String get stopRecording => 'Stop & Save';

  @override
  String get reRecord => 'Re-record';

  @override
  String get uploadConsultationAudio => 'Upload Consultation Audio';

  @override
  String get saveToQueue => 'Save & Queue for Sync';

  @override
  String get processingAudio => 'Processing Audio...';
}
