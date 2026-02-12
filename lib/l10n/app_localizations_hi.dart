// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'MechResQ';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get close => 'बंद करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get search => 'खोजें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get warning => 'चेतावनी';

  @override
  String get info => 'जानकारी';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageKannada => 'कन्नड़';

  @override
  String get languageTamil => 'तमिल';

  @override
  String get languageTelugu => 'तेलुगू';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get appearance => 'दिखावट';

  @override
  String get theme => 'थीम';

  @override
  String get appLanguage => 'ऐप भाषा';

  @override
  String get chooseTheme => 'थीम चुनें';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String themeSetTo(String theme) {
    return 'थीम $theme पर सेट की गई';
  }

  @override
  String languageChangedTo(String language) {
    return 'भाषा $language में बदली गई';
  }

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get enableNotifications => 'सूचनाएँ सक्षम करें';

  @override
  String get notificationsEnabled => 'आपको ऐप अपडेट मिलेंगे';

  @override
  String get notificationsDisabled => 'सभी सूचनाएँ बंद हैं';

  @override
  String get systemNotificationSettings => 'सिस्टम सूचना सेटिंग्स';

  @override
  String get manageOnDeviceLevel => 'डिवाइस स्तर पर प्रबंधित करें';

  @override
  String get openingSystemSettings =>
      'सिस्टम सूचना सेटिंग्स खोली जा रही हैं...';

  @override
  String get storage => 'स्टोरेज';

  @override
  String get cache => 'कैश';

  @override
  String currentlyUsing(String size) {
    return 'वर्तमान में $size उपयोग में है';
  }

  @override
  String get clear => 'साफ़ करें';

  @override
  String get clearCache => 'कैश साफ़ करें';

  @override
  String clearCacheMessage(String size) {
    return '$size अस्थायी डेटा हटाया जाएगा।';
  }

  @override
  String get cacheCleared => 'कैश सफलतापूर्वक साफ़ किया गया';

  @override
  String get dataUsage => 'डेटा उपयोग';

  @override
  String get storageBreakdown => 'स्टोरेज विवरण';

  @override
  String get total => 'कुल';

  @override
  String get profilePhotos => 'प्रोफ़ाइल फोटो';

  @override
  String get vehicleImages => 'वाहन चित्र';

  @override
  String get cachedMaps => 'कैश किए गए मानचित्र';

  @override
  String get serviceHistory => 'सेवा इतिहास';

  @override
  String get legal => 'कानूनी';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsAndConditions => 'नियम और शर्तें';

  @override
  String get privacyPolicyContent =>
      'अंतिम अपडेट: जनवरी 2026\n\nहम आपकी गोपनीयता का सम्मान करते हैं।';

  @override
  String get termsContent =>
      'अंतिम अपडेट: जनवरी 2026\n\nMechResQ का उपयोग करके आप शर्तों से सहमत हैं।';

  @override
  String get about => 'के बारे में';

  @override
  String get aboutMechResQ => 'MechResQ के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String aboutContent(String version, String build) {
    return 'MechResQ\nसंस्करण $version (बिल्ड $build)';
  }

  @override
  String get dangerZone => 'खतरे का क्षेत्र';

  @override
  String get resetAppPreferences => 'ऐप प्राथमिकताएँ रीसेट करें';

  @override
  String get restoreAllDefaults => 'सभी सेटिंग्स डिफ़ॉल्ट पर पुनर्स्थापित करें';

  @override
  String get resetPreferences => 'प्राथमिकताएँ रीसेट करें';

  @override
  String get resetPreferencesMessage => 'थीम और भाषा रीसेट हो जाएंगी।';

  @override
  String get reset => 'रीसेट करें';

  @override
  String get allPreferencesReset => 'सभी प्राथमिकताएँ डिफ़ॉल्ट पर रीसेट की गईं';

  @override
  String get loginTitle => 'Login';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterValidEmail => 'Enter valid email';

  @override
  String get enterPassword => 'Enter password';

  @override
  String minCharacters(int count) {
    return 'Min $count characters';
  }

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get userRole => 'User';

  @override
  String get mechanicRole => 'Mechanic';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get register => 'Register';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get googleLoginFailed => 'Google login failed';

  @override
  String get profileNotFound => 'Profile not found';
}
