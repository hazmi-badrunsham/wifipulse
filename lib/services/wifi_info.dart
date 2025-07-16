  import 'package:network_info_plus/network_info_plus.dart';

  
  String wifiName = "Unknown";
  String wifiBSSID = "Unknown";
  String wifiIP = "Unknown";
  String selectedTelco = '';
  bool isWifiConnected = true;

  Future<void> scanWifiInfo() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    final bssid = await info.getWifiBSSID();
    final ip = await info.getWifiIP();

      wifiName = ssid ?? 'Unavailable';
      wifiBSSID = bssid ?? 'Unavailable';
      wifiIP = ip ?? 'Unavailable';
      isWifiConnected = (ssid != null && ssid != '<unknown ssid>' && ssid.isNotEmpty);
      if (isWifiConnected) selectedTelco = '';
    }