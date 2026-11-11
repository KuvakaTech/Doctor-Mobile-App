// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get welcomeToKuvaka => 'कुवाका में आपका स्वागत है';

  @override
  String get selectModeDescription =>
      'कृपया परामर्श या प्रबंधन के लिए अपना मोड चुनें।';

  @override
  String get homeScreenConsultation => 'होम स्क्रीन / परामर्श';

  @override
  String get kioskTicketingFlow => 'किओस्क टिकट प्रवाह';

  @override
  String get loadingKiosk => 'किओस्क लोड हो रहा है...';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signingOut => 'साइन आउट हो रहा है...';

  @override
  String get confirmSignOut => 'क्या आप साइन आउट करना चाहते हैं?';

  @override
  String get welcomeTitle => 'स्मार्ट इतिहास।\nबेहतर परिणाम।';

  @override
  String get welcomeSubhead =>
      'AI-संचालित चिकित्सा इतिहास जो आपको आत्मविश्वास के साथ निदान करने और बिना बोझ के दस्तावेज़ीकरण करने में मदद करता है।';

  @override
  String get featureHistory => '5 मिनट से कम समय में संरचित रोगी इतिहास';

  @override
  String get featureDiagnoses => 'AI-जनरेटेड विभेदक निदान';

  @override
  String get featureSoap => 'तत्काल SOAP नोट दस्तावेज़ीकरण';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get loginTitle => 'वापसी पर आपका स्वागत है।';

  @override
  String get signInDescription =>
      'जारी रखने के लिए अपने खाते में साइन इन करें।';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get emailHint => 'doctor@hospital.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get signingIn => 'साइन इन हो रहा है...';

  @override
  String get newHere => 'यहाँ नए हैं?';

  @override
  String get createAnAccount => ' खाता बनाएं';

  @override
  String get createAccountTitle => 'अपना खाता बनाएं';

  @override
  String get createAccountDescription =>
      'आज ही स्मार्ट क्लिनिकल इतिहास लेना शुरू करें।';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get nameHint => 'डॉ. प्रिया शर्मा';

  @override
  String get creatingAccount => 'खाता बनाया जा रहा है...';

  @override
  String get alreadyHaveAccount => 'क्या आपके पास पहले से एक खाता मौजूद है?';

  @override
  String get unlockKiosk => 'किओस्क अनलॉक करें';

  @override
  String get unlockKioskDescription =>
      'शुरू करने के लिए 6-अंकों का किओस्क पिन दर्ज करें।';

  @override
  String get unlockingKiosk => 'किओस्क अनलॉक हो रहा है...';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get patientCheckIn => 'रोगी चेक-इन';

  @override
  String stepProgress(int step) {
    return 'चरण $step / 4';
  }

  @override
  String get enterPhoneNumber => 'फ़ोन नंबर दर्ज करें';

  @override
  String get phoneDescription =>
      'हम आपके परामर्श टिकट को जोड़ने के लिए इस फ़ोन नंबर का उपयोग करेंगे।';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get phoneHint => 'उदा. +91 98765 43210';

  @override
  String get selectVisitType => 'यात्रा का प्रकार चुनें';

  @override
  String get visitTypeDescription =>
      'क्या आप बाह्य रोगी (OPD) या भर्ती रोगी (IPD) परामर्श के लिए आए हैं?';

  @override
  String get visitType => 'यात्रा का प्रकार';

  @override
  String get opdOutpatient => 'OPD (बाह्य रोगी)';

  @override
  String get ipdInpatient => 'IPD (भर्ती रोगी)';

  @override
  String get selectPreferredLanguage => 'पसंदीदा भाषा चुनें';

  @override
  String get languageDescription =>
      'AI वॉयस असिस्टेंट के लिए अपनी पसंदीदा भाषा चुनें।';

  @override
  String get preferredLanguage => 'पसंदीदा भाषा';

  @override
  String get hindi => 'हिंदी (HI)';

  @override
  String get english => 'अंग्रेज़ी (EN)';

  @override
  String get marathi => 'मराठी (MR)';

  @override
  String get gujarati => 'गुजराती (GU)';

  @override
  String get selectGender => 'लिंग चुनें';

  @override
  String get genderDescription => 'कृपया रोगी का लिंग चुनें।';

  @override
  String get gender => 'लिंग';

  @override
  String get female => 'महिला';

  @override
  String get male => 'पुरुष';

  @override
  String get other => 'अन्य';

  @override
  String get next => 'आगे बढ़ें';

  @override
  String get startConsultationSession => 'परामर्श सत्र शुरू करें';

  @override
  String get startingSession => 'सत्र शुरू हो रहा है...';

  @override
  String get backToPreviousStep => 'पिछले चरण पर वापस जाएं';

  @override
  String get enterValidPin => 'कृपया एक वैध पिन दर्ज करें।';

  @override
  String get enterPhoneError => 'कृपया फ़ोन नंबर दर्ज करें।';

  @override
  String get unlockFailedError => 'अनलॉक विफल: अमान्य पिन या नेटवर्क त्रुटि।';

  @override
  String kioskConsultationTitle(String sessionId) {
    return 'किओस्क परामर्श ($sessionId)';
  }

  @override
  String get aiMedicalAgent => 'AI मेडिकल एजेंट';

  @override
  String get consultationSummaryReady => 'परामर्श सारांश तैयार है';

  @override
  String get noSummaryProvided => 'कोई सारांश प्रदान नहीं किया गया।';

  @override
  String get fetchingResult => 'परिणाम प्राप्त किया जा रहा है...';

  @override
  String get endSessionAndViewResult => 'सत्र समाप्त करें और परिणाम देखें';

  @override
  String get opdTicketAndResult => 'OPD टिकट और परिणाम';

  @override
  String get printModelToConsole => 'मॉडल कंसोल पर प्रिंट करें';

  @override
  String get hospitalOpdTicket => 'अस्पताल OPD टिकट';

  @override
  String get ticketRegisteredSuccessfully => 'टिकट सफलतापूर्वक पंजीकृत हुआ';

  @override
  String dateLabel(String date) {
    return 'दिनांक: $date';
  }

  @override
  String get ticketNumber => 'टिकट संख्या';

  @override
  String get departmentCategory => 'विभाग / श्रेणी: ';

  @override
  String get patientDetails => 'रोगी का विवरण';

  @override
  String get consultationSummary => 'परामर्श सारांश';

  @override
  String get clinicalAlertsAndFlags => 'नैदानिक अलर्ट और झंडे';

  @override
  String get finishAndReturnToKioskHome => 'समाप्त करें और किओस्क होम पर लौटें';

  @override
  String get nameLabel => 'नाम';

  @override
  String get patientIdLabel => 'रोगी आईडी';

  @override
  String get phoneLabel => 'फ़ोन';

  @override
  String get demographicsLabel => 'जनसांख्यिकी';

  @override
  String get guardianLabel => 'अभिभावक';

  @override
  String get addressLabel => 'पता';

  @override
  String get categoryCasteLabel => 'श्रेणी / जाति';

  @override
  String get patients => 'रोगी';

  @override
  String get managePatientRecords => 'अपने रोगी रिकॉर्ड का प्रबंधन करें';

  @override
  String get searchHint => 'खोजें...';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get noPatientRecords => 'कोई रोगी रिकॉर्ड नहीं है';

  @override
  String loggedInAs(String name) {
    return 'लॉग इन: $name';
  }

  @override
  String get confirmLogout => 'क्या आप लॉग आउट करना चाहते हैं?';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get loggingOut => 'लॉग आउट हो रहा है...';

  @override
  String get failedToFetchHistory => 'रोगी का इतिहास प्राप्त करने में विफल।';

  @override
  String get startNewSession => 'नया सत्र शुरू करें';

  @override
  String get medicalConsultation => 'चिकित्सा परामर्श';

  @override
  String get standardAiAssistedHistory => 'मानक AI-सहायता प्राप्त इतिहास लेना';

  @override
  String get cabinFlow => 'केबिन प्रवाह';

  @override
  String get doctorLedLiveConsultation => 'डॉक्टर के नेतृत्व में सीधा परामर्श';

  @override
  String get audioRecording => 'ऑडियो रिकॉर्डिंग';

  @override
  String get recordAudioSession => 'ऑडियो परामर्श सत्र रिकॉर्ड करें';

  @override
  String get consultationHistory => 'परामर्श इतिहास';

  @override
  String get cabinSessions => 'केबिन सत्र';

  @override
  String get historyTab => 'इतिहास';

  @override
  String get cabinTab => 'केबिन';

  @override
  String get noConsultationsYet => 'अभी तक कोई परामर्श नहीं हुआ है';

  @override
  String get startFirstConsultationPrompt =>
      'नीचे दिए गए बटन का उपयोग करके पहला सत्र शुरू करें।';

  @override
  String get deleteConsultationConfirm =>
      'क्या आप इस परामर्श को हटाना चाहते हैं?';

  @override
  String get deleting => 'हटाया जा रहा है...';

  @override
  String get consultationDeletedSuccess => 'परामर्श सफलतापूर्वक हटा दिया गया';

  @override
  String get deleteCabinConfirm =>
      'क्या आप इस केबिन परामर्श को हटाना चाहते हैं?';

  @override
  String get cabinDeletedSuccess => 'केबिन परामर्श सफलतापूर्वक हटा दिया गया';

  @override
  String deleteSelectedSessionsConfirm(int count) {
    return 'क्या आप चुने गए $count सत्र हटाना चाहते हैं?';
  }

  @override
  String selectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get pdfSaved => 'PDF सहेजा गया';

  @override
  String savedTo(String location) {
    return 'यहाँ सहेजा गया: $location';
  }

  @override
  String get open => 'खोलें';

  @override
  String audioRecordingTitle(String patientName) {
    return 'ऑडियो रिकॉर्डिंग - $patientName';
  }

  @override
  String get offlineModeBadge => 'ऑफ़लाइन मोड';

  @override
  String get onlineModeBadge => 'ऑनलाइन मोड';

  @override
  String get offlineSyncNotice =>
      'कोई इंटरनेट कनेक्शन नहीं है। रिकॉर्डिंग स्थानीय रूप से सहेजी जाएगी और ऑनलाइन होने पर ऑटो-सिंक की जाएगी।';

  @override
  String get onlineSyncNotice =>
      'सर्वर से कनेक्टेड। पूरा होने पर रिकॉर्डिंग तुरंत प्रोसेस की जाएगी।';

  @override
  String get readyToRecord => 'रिकॉर्डिंग के लिए तैयार';

  @override
  String get recordingInProgress => 'परामर्श रिकॉर्ड हो रहा है...';

  @override
  String get recordingPaused => 'रिकॉर्डिंग रोकी गई';

  @override
  String get recordingComplete => 'रिकॉर्डिंग पूर्ण';

  @override
  String get tapToStartRecording =>
      'परामर्श सत्र की रिकॉर्डिंग शुरू करने के लिए माइक्रोफ़ोन बटन पर टैप करें।';

  @override
  String get startRecording => 'रिकॉर्डिंग शुरू करें';

  @override
  String get pauseRecording => 'रोकें';

  @override
  String get resumeRecording => 'पुनः शुरू करें';

  @override
  String get stopRecording => 'रोकें और सहेजें';

  @override
  String get reRecord => 'पुनः रिकॉर्ड करें';

  @override
  String get uploadConsultationAudio => 'परामर्श ऑडियो अपलोड करें';

  @override
  String get saveToQueue => 'सहेजें और सिंक के लिए कतारबद्ध करें';

  @override
  String get processingAudio => 'ऑडियो प्रोसेस हो रहा है...';
}
