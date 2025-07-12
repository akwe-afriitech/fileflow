// A simple model to represent a discovered service on the network.
class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;
  String status; // e.g., 'Available', 'Connected', 'Failed'

  DiscoveredDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.status = 'Available',
  });

  // Optional: For easy debugging and checking for duplicates.
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