abstract class ConnectionConfig {
  String get type;
  Map<String, dynamic> toJson();

  // Global Registry: Maps 'type' string to a factory function
  static final Map<String, ConnectionConfig Function(Map<String, dynamic>)> _registry = {
    'tcp': TcpConfig.fromJson,
    // Add new types here
  };

  // The global conversion method
  static ConnectionConfig fromMap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null || !_registry.containsKey(type)) {
      throw Exception("Unsupported or missing connection type: $type");
    }
    return _registry[type]!(data);
  }
}

class TcpConfig extends ConnectionConfig {
  @override
  String get type => 'tcp';
  
  final String ip;
  final int port;

  TcpConfig({required this.ip, required this.port});

  @override
  Map<String, dynamic> toJson() => {'type': type, 'ip': ip, 'port': port};

  factory TcpConfig.fromJson(Map<String, dynamic> json) => TcpConfig(
        ip: json['ip'] ?? '127.0.0.1',
        port: json['port'] ?? 8080,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TcpConfig &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}