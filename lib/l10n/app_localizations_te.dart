// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'MechResQ';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get close => 'మూసివేయండి';

  @override
  String get confirm => 'నిర్ధారించండి';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get delete => 'తొలగించండి';

  @override
  String get edit => 'సవరించండి';

  @override
  String get search => 'వెతకండి';

  @override
  String get loading => 'లోడ్ అవుతోంది...';

  @override
  String get error => 'లోపం';

  @override
  String get success => 'విజయం';

  @override
  String get warning => 'హెచ్చరిక';

  @override
  String get info => 'సమాచారం';

  @override
  String get languageEnglish => 'ఇంగ్లీష్';

  @override
  String get languageHindi => 'హిందీ';

  @override
  String get languageKannada => 'కన్నడ';

  @override
  String get languageTamil => 'తమిళం';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get settings => 'సెట్టింగ్స్';

  @override
  String get appearance => 'రూపం';

  @override
  String get theme => 'థీమ్';

  @override
  String get appLanguage => 'యాప్ భాష';

  @override
  String get chooseTheme => 'థీమ్ ఎంచుకోండి';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get themeSystem => 'సిస్టమ్';

  @override
  String themeSetTo(String theme) {
    return 'థీమ్ $theme గా సెట్ చేయబడింది';
  }

  @override
  String languageChangedTo(String language) {
    return 'భాష $language కు మార్చబడింది';
  }

  @override
  String get notifications => 'నోటిఫికేషన్లు';

  @override
  String get enableNotifications => 'నోటిఫికేషన్లు ప్రారంభించండి';

  @override
  String get notificationsEnabled => 'మీకు యాప్ అప్డేట్లు అందుతాయి';

  @override
  String get notificationsDisabled => 'అన్ని నోటిఫికేషన్లు ఆఫ్‌లో ఉన్నాయి';

  @override
  String get systemNotificationSettings => 'System Notification Settings';

  @override
  String get manageOnDeviceLevel => 'Manage on device level';

  @override
  String get openingSystemSettings => 'Opening system notification settings...';

  @override
  String get storage => 'స్టోరేజ్';

  @override
  String get cache => 'క్యాష్';

  @override
  String currentlyUsing(String size) {
    return 'ప్రస్తుతం $size ఉపయోగంలో ఉంది';
  }

  @override
  String get clear => 'క్లియర్ చేయండి';

  @override
  String get clearCache => 'క్యాష్ క్లియర్ చేయండి';

  @override
  String clearCacheMessage(String size) {
    return '$size తాత్కాలిక డేటా తొలగించబడుతుంది.';
  }

  @override
  String get cacheCleared => 'క్యాష్ విజయవంతంగా క్లియర్ చేయబడింది';

  @override
  String get dataUsage => 'డేటా వినియోగం';

  @override
  String get storageBreakdown => 'స్టోరేజ్ వివరాలు';

  @override
  String get total => 'మొత్తం';

  @override
  String get profilePhotos => 'ప్రొఫైల్ ఫోటోలు';

  @override
  String get vehicleImages => 'వాహన చిత్రాలు';

  @override
  String get cachedMaps => 'క్యాష్ చేసిన మ్యాప్స్';

  @override
  String get serviceHistory => 'సర్వీస్ చరిత్ర';

  @override
  String get legal => 'చట్టపరమైనవి';

  @override
  String get privacyPolicy => 'గోప్యతా విధానం';

  @override
  String get termsAndConditions => 'నియమాలు & షరతులు';

  @override
  String get privacyPolicyContent =>
      'Last updated: January 2026\n\nWe respect your privacy. Your data is stored securely and encrypted. We never sell your data. Location is used only to find nearby mechanics.\n\nContact: support@mechresq.com';

  @override
  String get termsContent =>
      'Last updated: January 2026\n\nBy using MechResQ, you agree to our terms. You must be 18+. We are not liable for disputes between users and mechanics.\n\nContact: support@mechresq.com';

  @override
  String get about => 'గురించి';

  @override
  String get aboutMechResQ => 'MechResQ గురించి';

  @override
  String get version => 'వెర్షన్';

  @override
  String aboutContent(String version, String build) {
    return 'MechResQ\nవెర్షన్ $version (బిల్డ్ $build)\n\nనమ్మదగిన వాహన బ్రేక్‌డౌన్ సహాయ యాప్.';
  }

  @override
  String get dangerZone => 'ప్రమాద ప్రాంతం';

  @override
  String get resetAppPreferences => 'యాప్ ప్రాధాన్యతలను రీసెట్ చేయండి';

  @override
  String get restoreAllDefaults => 'అన్ని సెట్టింగులను రీసెట్ చేయండి';

  @override
  String get resetPreferences => 'ప్రాధాన్యతలను రీసెట్ చేయండి';

  @override
  String get resetPreferencesMessage =>
      'ఇది థీమ్, భాష మరియు నోటిఫికేషన్ సెట్టింగులను రీసెట్ చేస్తుంది.';

  @override
  String get reset => 'రీసెట్';

  @override
  String get allPreferencesReset => 'అన్ని ప్రాధాన్యతలు రీసెట్ చేయబడ్డాయి';

  @override
  String get loginTitle => 'లాగిన్';

  @override
  String get welcomeBack => 'మళ్లీ స్వాగతం';

  @override
  String get emailLabel => 'ఇమెయిల్';

  @override
  String get passwordLabel => 'పాస్‌వర్డ్';

  @override
  String get enterEmail => 'ఇమెయిల్ నమోదు చేయండి';

  @override
  String get enterValidEmail => 'సరైన ఇమెయిల్ నమోదు చేయండి';

  @override
  String get enterPassword => 'పాస్‌వర్డ్ నమోదు చేయండి';

  @override
  String minCharacters(int count) {
    return 'కనీసం $count అక్షరాలు';
  }

  @override
  String get forgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get userRole => 'యూజర్';

  @override
  String get mechanicRole => 'మెకానిక్';

  @override
  String get signInWithGoogle => 'Google తో లాగిన్ చేయండి';

  @override
  String get noAccount => 'ఖాతా లేదా?';

  @override
  String get register => 'నమోదు';

  @override
  String get loginFailed => 'లాగిన్ విఫలమైంది';

  @override
  String get googleLoginFailed => 'Google లాగిన్ విఫలమైంది';

  @override
  String get profileNotFound => 'ప్రొఫైల్ కనుగొనబడలేదు';
}
