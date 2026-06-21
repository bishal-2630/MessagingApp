import 'package:flutter/foundation.dart';

String getBaseUrl() {
  if (kIsWeb) {
    return Uri.base.origin;
  }
  return 'http://10.0.2.2:8000';
}
