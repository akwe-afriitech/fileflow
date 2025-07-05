class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;
  String status; 

  DiscoveredDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.status = 'Available',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => name.hashCode ^ ip.hashCode ^ port.hashCode;
}