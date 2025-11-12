import 'package:hugeicons/hugeicons.dart';

/// App Icons - Uses HugeIcons
/// Note: HugeIcons returns List of Lists (icon path data), not IconData
/// Use HugeIcon widget to render these icons
class AppIcons {
  // Navigation
  static const List<List<dynamic>> arrowRight =
      HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> arrowLeft =
      HugeIcons.strokeRoundedArrowLeft01;

  // User & Profile
  static const List<List<dynamic>> user = HugeIcons.strokeRoundedUser02;
  static const List<List<dynamic>> settings = HugeIcons.strokeRoundedSettings01;
  static const List<List<dynamic>> logout = HugeIcons.strokeRoundedLogout01;

  // Delivery & Package
  static const List<List<dynamic>> box = HugeIcons.strokeRoundedPackage01;
  static const List<List<dynamic>> car = HugeIcons.strokeRoundedCar01;
  static const List<List<dynamic>> checkmarkCircle =
      HugeIcons.strokeRoundedCheckmarkCircle01;

  // Communication
  static const List<List<dynamic>> chat = HugeIcons.strokeRoundedChatting01;
  static const List<List<dynamic>> phone =
      HugeIcons.strokeRoundedPhoneArrowDown;
  static const List<List<dynamic>> bell = HugeIcons.strokeRoundedNotification01;

  // Navigation & Map
  static const List<List<dynamic>> home = HugeIcons.strokeRoundedHome01;
  static const List<List<dynamic>> map = HugeIcons.strokeRoundedMaping;
  static const List<List<dynamic>> list = HugeIcons.strokeRoundedListView;

  // Services
  static const List<List<dynamic>> search = HugeIcons.strokeRoundedSearch01;
  static const List<List<dynamic>> filter = HugeIcons.strokeRoundedFilter;
  static const List<List<dynamic>> calculator =
      HugeIcons.strokeRoundedCalculator;
  static const List<List<dynamic>> receipt =
      HugeIcons.strokeRoundedReceiptDollar;
  static const List<List<dynamic>> lifebuoy = HugeIcons.strokeRoundedLifebuoy;
  static const List<List<dynamic>> add = HugeIcons.strokeRoundedPlusSign;

  // Additional
  static const List<List<dynamic>> clock =
      HugeIcons.strokeRoundedSettings01; // Clock alternative
  static const List<List<dynamic>> idCard = HugeIcons.strokeRoundedUser02;
  static const List<List<dynamic>> document = HugeIcons.strokeRoundedFile01;
  static const List<List<dynamic>> send = HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> plus = HugeIcons.strokeRoundedPlusSign;
  static const List<List<dynamic>> minus = HugeIcons.strokeRoundedMinusSign;
  static const List<List<dynamic>> close = HugeIcons.strokeRoundedCancel01;
}
