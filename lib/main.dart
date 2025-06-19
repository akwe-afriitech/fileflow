import 'package:fileflow/components/filecomponent.dart';
import 'package:fileflow/components/qrcode.dart';
import 'package:fileflow/components/settingcomponent.dart';
import 'package:fileflow/components/transfercomponent.dart';
import 'package:fileflow/screens/home.dart';
import 'package:fileflow/screens/wifidirect.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileShare Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming Inter font is imported or default is fine
      ),
      home: const AppScreenManager(),
    );
  }
}

class AppScreenManager extends StatefulWidget {
  const AppScreenManager({super.key});

  @override
  State<AppScreenManager> createState() => _AppScreenManagerState();
}

class _AppScreenManagerState extends State<AppScreenManager> {
  String _currentScreen = 'home';

  void _setCurrentScreen(String screenName) {
    setState(() {
      _currentScreen = screenName;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    switch (_currentScreen) {
      case 'home':
        currentWidget = HomeScreen(setCurrentScreen: _setCurrentScreen);
        break;
      case 'transfer':
        currentWidget = TransferScreen(setCurrentScreen: _setCurrentScreen);
        break;
      case 'fileSelect':
        currentWidget = FileSelectScreen(setCurrentScreen: _setCurrentScreen);
        break;
      case 'settings':
        currentWidget = SettingsScreen(setCurrentScreen: _setCurrentScreen);
        break;
      case 'qrCode':
        currentWidget = QRCodeScreen(setCurrentScreen: _setCurrentScreen);
        break;
      case 'wifiDirect':
        currentWidget = WiFiDirectScreen(setCurrentScreen: _setCurrentScreen);
        break;
      default:
        currentWidget = HomeScreen(setCurrentScreen: _setCurrentScreen);
    }

    return Scaffold(
      body: Center(
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
          color: Colors.grey.withAlpha((0.2 * 255).toInt()),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(0, 3),
          ),
        ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: currentWidget,
        ),
      ),
      ),
    );
  }
}



