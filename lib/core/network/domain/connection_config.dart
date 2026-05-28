abstract class ConnectionConfig {
  String get displayName;
}

class TcpConfig extends ConnectionConfig {
  final String host;
  final int port;
  TcpConfig({required this.host,required this.port});
  
  @override
  String get displayName => "$host:$port";
}

