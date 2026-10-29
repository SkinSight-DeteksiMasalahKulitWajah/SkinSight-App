import 'package:flutter/foundation.dart';

class ProfileData extends ChangeNotifier {
  String name = 'Alea Kucing';
  String phone = '+62 812-3456-7890';
  String email = 'alea.kucing@email.com';
  Uint8List? photoBytes;

  void updateName(String value) {
    name = value;
    notifyListeners();
  }

  void updatePhone(String value) {
    phone = value;
    notifyListeners();
  }

  void updateEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updatePhoto(Uint8List value) {
    photoBytes = value;
    notifyListeners();
  }
}
