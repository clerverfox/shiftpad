import 'dart:typed_data';

const int kZwiftCompanyId = 0x094A;
const int kRightSideByte = 0x0A;
const int kLeftSideByte = 0x0B;

const String kClickService = '00000001-19ca-4651-86e5-fa29dcdd09d1';
const String kClickServiceAlt = '0000fc82-0000-1000-8000-00805f9b34fb';
const String kAsyncChar = '00000002-19ca-4651-86e5-fa29dcdd09d1';
const String kSyncRxChar = '00000003-19ca-4651-86e5-fa29dcdd09d1';
const String kSyncTxChar = '00000004-19ca-4651-86e5-fa29dcdd09d1';

const String kBatteryService = '0000180f-0000-1000-8000-00805f9b34fb';
const String kBatteryLevelChar = '00002a19-0000-1000-8000-00805f9b34fb';
const String kDeviceInfoService = '0000180a-0000-1000-8000-00805f9b34fb';
const String kFirmwareRevisionChar = '00002a26-0000-1000-8000-00805f9b34fb';

final Uint8List kRideOn =
    Uint8List.fromList([0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E]);
final Uint8List kHandshakeV2 = Uint8List.fromList([...kRideOn, 0x02, 0x03]);
final Uint8List kActivate1 = Uint8List.fromList([0x00, 0x08, 0x00]);
final Uint8List kActivate2 = Uint8List.fromList([0x00, 0x08, 0x10]);
final Uint8List kKeepUnlocked = Uint8List.fromList([0xFF, 0x04, 0x00]);
final Uint8List kReboot = Uint8List.fromList([0x18]);

const int kOpButtons = 0x23;
const int kOpBattery = 0x19;
const int kOpDeviceInfo = 0x3C;
const int kOpLockChallenge = 0xFF;
