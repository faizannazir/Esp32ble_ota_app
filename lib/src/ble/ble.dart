import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final ble = FlutterReactiveBle();

bool isBleReady(BleStatus status) {
  return status == BleStatus.ready;
}