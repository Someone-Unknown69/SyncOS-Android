abstract class ConnectionConfig {
  Map<String, dynamic> get getConfig;
}

class TcpConfig extends ConnectionConfig {
  final String host;
  final int port;
  TcpConfig({required this.host,required this.port});

  factory TcpConfig.fromAddress(String host, int port) {
    return TcpConfig(host: host, port: port);
  }
  
  @override
  Map<String, dynamic> get getConfig => {
    'host' : host,
    'port' : port,
  };
}

