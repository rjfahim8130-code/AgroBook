import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction_model.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Hive অ্যাডাপ্টার রেজিস্টার (যদি কোড জেনারেটর ব্যবহার না করে ম্যানুয়াল বা জেনারেটেড ফাইল হয়)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }

  await Hive.openBox('settingsBox');
  await Hive.openBox<TransactionModel>('transactionsBox');

  runApp(const AgroBookApp());
}

class AgroBookApp extends StatelessWidget {
  const AgroBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey.shade100,
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: _checkFirstTime(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            bool isFirstTime = snapshot.data ?? true;
            return isFirstTime ? const WelcomeScreen() : const HomeScreen();
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        },
      ),
    );
  }

  Future<bool> _checkFirstTime() async {
    var box = Hive.box('settingsBox');
    return box.get('isFirstTime', defaultValue: true);
  }
}
