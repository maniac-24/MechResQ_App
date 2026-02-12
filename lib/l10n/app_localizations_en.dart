// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MechResQ';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageKannada => 'Kannada';

  @override
  String get languageTamil => 'Tamil';

  @override
  String get languageTelugu => 'Telugu';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get appLanguage => 'App Language';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String themeSetTo(String theme) {
    return 'Theme set to $theme';
  }

  @override
  String languageChangedTo(String language) {
    return 'Language changed to $language';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get notificationsEnabled => 'You will receive app updates';

  @override
  String get notificationsDisabled => 'All notifications are off';

  @override
  String get systemNotificationSettings => 'System Notification Settings';

  @override
  String get manageOnDeviceLevel => 'Manage on device level';

  @override
  String get openingSystemSettings => 'Opening system notification settings...';

  @override
  String get storage => 'Storage';

  @override
  String get cache => 'Cache';

  @override
  String currentlyUsing(String size) {
    return 'Currently using $size';
  }

  @override
  String get clear => 'Clear';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String clearCacheMessage(String size) {
    return 'This will remove $size of temporary data. The app may load slightly slower on next use.';
  }

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get storageBreakdown => 'Storage Breakdown';

  @override
  String get total => 'Total';

  @override
  String get profilePhotos => 'Profile Photos';

  @override
  String get vehicleImages => 'Vehicle Images';

  @override
  String get cachedMaps => 'Cached Maps';

  @override
  String get serviceHistory => 'Service History';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get privacyPolicyContent =>
      'Last updated: January 2026\n\nWe respect your privacy. Your data is stored securely and encrypted. We never sell your data. Location is used only to find nearby mechanics.\n\nContact: support@mechresq.com';

  @override
  String get termsContent =>
      'Last updated: January 2026\n\nBy using MechResQ, you agree to our terms. You must be 18+. We are not liable for disputes between users and mechanics.\n\nContact: support@mechresq.com';

  @override
  String get about => 'About';

  @override
  String get aboutMechResQ => 'About MechResQ';

  @override
  String get version => 'Version';

  @override
  String aboutContent(String version, String build) {
    return 'MechResQ\nVersion $version (Build $build)\n\nA reliable vehicle breakdown assistance app.';
  }

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetAppPreferences => 'Reset App Preferences';

  @override
  String get restoreAllDefaults => 'Restore all settings to defaults';

  @override
  String get resetPreferences => 'Reset Preferences';

  @override
  String get resetPreferencesMessage =>
      'This will reset theme, language, and notification settings to defaults.';

  @override
  String get reset => 'Reset';

  @override
  String get allPreferencesReset => 'All preferences reset to defaults';

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
