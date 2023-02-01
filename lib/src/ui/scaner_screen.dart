import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock/wakelock.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:ble_ota_app/src/ble/ble.dart';
import 'package:ble_ota_app/src/ble/ble_scanner.dart';
import 'package:ble_ota_app/src/ble/ble_uuids.dart';
import 'package:ble_ota_app/src/ui/status_screen.dart';
import 'package:ble_ota_app/src/ui/settings_screen.dart';
import 'package:ble_ota_app/src/ui/upload_screen.dart';
import 'package:ble_ota_app/src/settings/settings.dart';

class ScanerScreen extends StatefulWidget {
  const ScanerScreen({super.key});

  @override
  State<ScanerScreen> createState() => ScanerScreenState();
}

class ScanerScreenState extends State<ScanerScreen> {
  void _evaluateBleStatus(BleStatus status) {
    setState(() {
      if (status == BleStatus.ready) {
        _startScan();
      } else if (status != BleStatus.unknown) {
        _stopScan();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StatusScreen()),
        );
      }
    });
  }

  void _startScan() {
    Wakelock.enable();
    bleScanner.startScan([serviceUuid]);

    if (!infiniteScan.value) {
      Future.delayed(const Duration(seconds: 10), _stopScan);
    }
  }

  void _stopScan() {
    Wakelock.disable();
    bleScanner.stopScan();
  }

  Widget _buildDeviceCard(device) => Card(
        child: ListTile(
          title: Text(device.name),
          subtitle: Text("${device.id}\nRSSI: ${device.rssi}"),
          leading: const Icon(Icons.bluetooth),
          onTap: () async {
            _stopScan();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UploadScreen(deviceId: device.id, deviceName: device.name),
              ),
            );
          },
        ),
      );

  Widget _buildDevicesList() {
    final devices = bleScanner.state.discoveredDevices;
    final additionalElement = bleScanner.state.scanIsInProgress ? 1 : 0;

    return ListView.builder(
      itemCount: devices.length + additionalElement,
      itemBuilder: (context, index) => index != devices.length
          ? _buildDeviceCard(devices[index])
          : const Padding(
              padding: EdgeInsets.all(25.0),
              child: JumpingDots(
                color: Colors.grey,
                radius: 6,
                innerPadding: 5,
              ),
            ),
    );
  }

  @override
  void initState() {
    ble.statusStream.listen(_evaluateBleStatus);
    _evaluateBleStatus(ble.status);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Devices')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              _stopScan();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: StreamBuilder<BleScanState>(
            stream: bleScanner.stateStream,
            builder: (context, snapshot) => Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: _buildDevicesList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(tr('Scan')),
                      onPressed: !bleScanner.state.scanIsInProgress
                          ? _startScan
                          : null,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search_off),
                      label: Text(tr('Stop')),
                      onPressed:
                          bleScanner.state.scanIsInProgress ? _stopScan : null,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
