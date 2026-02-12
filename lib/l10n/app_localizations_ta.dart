// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'MechResQ';

  @override
  String get cancel => 'ரத்து செய்யவும்';

  @override
  String get close => 'மூடு';

  @override
  String get confirm => 'உறுதிப்படுத்து';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get delete => 'நீக்கு';

  @override
  String get edit => 'திருத்து';

  @override
  String get search => 'தேடு';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get warning => 'எச்சரிக்கை';

  @override
  String get info => 'தகவல்';

  @override
  String get languageEnglish => 'ஆங்கிலம்';

  @override
  String get languageHindi => 'இந்தி';

  @override
  String get languageKannada => 'கன்னடம்';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get languageTelugu => 'தெலுங்கு';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get appearance => 'தோற்றம்';

  @override
  String get theme => 'தீம்';

  @override
  String get appLanguage => 'ஆப் மொழி';

  @override
  String get chooseTheme => 'தீமைத் தேர்ந்தெடுக்கவும்';

  @override
  String get themeLight => 'லைட்';

  @override
  String get themeDark => 'டார்க்';

  @override
  String get themeSystem => 'சிஸ்டம்';

  @override
  String themeSetTo(String theme) {
    return 'தீம் $theme ஆக மாற்றப்பட்டது';
  }

  @override
  String languageChangedTo(String language) {
    return 'மொழி $language ஆக மாற்றப்பட்டது';
  }

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get enableNotifications => 'அறிவிப்புகளை செயல்படுத்து';

  @override
  String get notificationsEnabled => 'நீங்கள் ஆப் புதுப்பிப்புகளை பெறுவீர்கள்';

  @override
  String get notificationsDisabled =>
      'அனைத்து அறிவிப்புகளும் நிறுத்தப்பட்டுள்ளன';

  @override
  String get systemNotificationSettings => 'சிஸ்டம் அறிவிப்பு அமைப்புகள்';

  @override
  String get manageOnDeviceLevel => 'சாதன மட்டத்தில் நிர்வகிக்கவும்';

  @override
  String get openingSystemSettings =>
      'சிஸ்டம் அறிவிப்பு அமைப்புகள் திறக்கப்படுகிறது...';

  @override
  String get storage => 'சேமிப்பு';

  @override
  String get cache => 'கேஷ்';

  @override
  String currentlyUsing(String size) {
    return 'தற்போது $size பயன்படுத்தப்படுகிறது';
  }

  @override
  String get clear => 'அழிக்கவும்';

  @override
  String get clearCache => 'கேஷ் அழிக்கவும்';

  @override
  String clearCacheMessage(String size) {
    return '$size தற்காலிக தரவு நீக்கப்படும்.';
  }

  @override
  String get cacheCleared => 'கேஷ் வெற்றிகரமாக அழிக்கப்பட்டது';

  @override
  String get dataUsage => 'தரவு பயன்பாடு';

  @override
  String get storageBreakdown => 'சேமிப்பு விவரம்';

  @override
  String get total => 'மொத்தம்';

  @override
  String get profilePhotos => 'சுயவிவர புகைப்படங்கள்';

  @override
  String get vehicleImages => 'வாகன படங்கள்';

  @override
  String get cachedMaps => 'கேஷ் செய்யப்பட்ட வரைபடங்கள்';

  @override
  String get serviceHistory => 'சேவை வரலாறு';

  @override
  String get legal => 'சட்டம்';

  @override
  String get privacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get termsAndConditions => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்';

  @override
  String get privacyPolicyContent => 'கடைசியாக புதுப்பிக்கப்பட்டது: ஜனவரி 2026';

  @override
  String get termsContent =>
      'MechResQ பயன்படுத்துவதன் மூலம், நீங்கள் விதிமுறைகளை ஏற்கிறீர்கள்.';

  @override
  String get about => 'பற்றி';

  @override
  String get aboutMechResQ => 'MechResQ பற்றி';

  @override
  String get version => 'பதிப்பு';

  @override
  String aboutContent(String version, String build) {
    return 'MechResQ\nபதிப்பு $version (Build $build)';
  }

  @override
  String get dangerZone => 'ஆபத்து பகுதி';

  @override
  String get resetAppPreferences => 'ஆப் விருப்பங்களை மீட்டமை';

  @override
  String get restoreAllDefaults =>
      'அனைத்து அமைப்புகளையும் இயல்புநிலைக்கு மாற்றவும்';

  @override
  String get resetPreferences => 'விருப்பங்களை மீட்டமை';

  @override
  String get resetPreferencesMessage =>
      'தீம் மற்றும் மொழி இயல்புநிலைக்கு மாற்றப்படும்.';

  @override
  String get reset => 'மீட்டமை';

  @override
  String get allPreferencesReset =>
      'அனைத்து விருப்பங்களும் இயல்புநிலைக்கு மாற்றப்பட்டன';

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
