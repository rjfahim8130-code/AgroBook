import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction_model.dart';
import 'providers/farm_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }

  await Hive.openBox('settingsBox');
  await Hive.openBox<TransactionModel>('transactionsBox');

  runApp(
    ChangeNotifierProvider(
      create: (context) => FarmProvider(),
      child: const AgroBookApp(),
    ),
  );
}

class AgroBookApp extends StatelessWidget {
  const AgroBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('settingsBox');
    bool isFirstTime = box.get('isFirstTime', defaultValue: true);

    return MaterialApp(
      title: 'AgroBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // প্রফেশনাল সবুজ
          surface: const Color(0xFFF5F5F5), // আরামদায়ক ব্যাকগ্রাউন্ড
        ),
        useMaterial3: true,
      ),
      home: isFirstTime ? const WelcomeScreen() : const HomeScreen(),
    );
  }
}
