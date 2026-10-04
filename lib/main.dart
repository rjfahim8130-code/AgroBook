import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction_model.dart';
import 'providers/farm_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive ইনিশিয়ালাইজেশন
  await Hive.initFlutter();
  
  // Model Adapter রেজিস্টার
  Hive.registerAdapter(TransactionModelAdapter());

  // Hive Box ওপেন করা
  await Hive.openBox<TransactionModel>('transactionsBox');
  await Hive.openBox('settingsBox');

  runApp(const AgroBookApp());
}

class AgroBookApp extends StatelessWidget {
  const AgroBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProvider()),
      ],
      child: MaterialApp(
        title: 'AgroBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
