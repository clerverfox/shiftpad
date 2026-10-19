import 'dart:typed_data';

import '../core/click_button.dart';
import 'click_constants.dart';

/// Returns which pod an advertisement comes from, or null if it is not a Click V2.
ClickSide? sideFromManufacturerData(int companyId, Uint8List data) {
  if (companyId != kZwiftCompanyId || data.isEmpty) return null;
  return switch (data[0]) {
    kRightSideByte => ClickSide.right,
    kLeftSideByte => ClickSide.left,
    _ => null,
  };
}
