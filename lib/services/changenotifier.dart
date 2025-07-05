import 'dart:io';
import 'package:flutter/material.dart';

class ConnectionService with ChangeNotifier {
  // Private state variables
  Socket? _socket;
  String _status = "Not Connected";
  bool _isConnected = false;

  // Public getters for UI to access
  Socket? get socket => _socket;
  String get status => _status;
  bool get isConnected => _isConnected;

  // Method to update the connection state
  void setConnection(Socket clientSocket) {
    _socket = clientSocket;
    _isConnected = true;
    _status = "Connected to ${clientSocket.remoteAddress.address}";
    
    // Crucially, notify all listening widgets that the state has changed
    notifyListeners();

    // Listen for the socket to close
    _socket!.done.then((_) {
      disconnect();
    });
  }

  // Method to clear the connection state
  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    _status = "Disconnected";
    notifyListeners();
  }
}