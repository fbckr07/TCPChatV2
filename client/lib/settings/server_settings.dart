import 'package:tcpchatv2_client/config/app_constants.dart';

class ServerSettings {
  static String _host = AppConstants.defaultHost;
  static int _port = AppConstants.defaultPort;

  static String get host => _host;
  static int get port => _port;

  static void setHost(String newHost) {
    _host = newHost;
  }

  static void setPort(int newPort) {
    _port = newPort;
  }

  static void setServerAddress(String host, int port) {
    _host = host;
    _port = port;
  }

  static Map<String, dynamic> toMap() {
    return {'host': _host, 'port': _port};
  }

  static void fromMap(Map<String, dynamic> map) {
    _host = map['host'] ?? AppConstants.defaultHost;
    _port = map['port'] ?? AppConstants.defaultPort;
  }
}
