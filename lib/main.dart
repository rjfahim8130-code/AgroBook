import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/transaction_model.dart';
import 'models/batch_model.dart';
import 'models/personal_transaction_model.dart';
import 'providers/farm_provider.dart';
import 'providers/personal_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive ইনিশিয়ালাইজেশন
  await Hive.initFlutter();

  // অ্যাডাপ্টার রেজিস্টার
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BatchModelAdapter());
  Hive.registerAdapter(PersonalTransactionModelAdapter());

  // বক্স ওপেন
  await Hive.openBox<TransactionModel>('farm_transactions');
  await Hive.openBox<BatchModel>('batches');
  await Hive.openBox<PersonalTransactionModel>('personal_transactions');
  await Hive.openBox('settings');

  runApp(const AgroBookApp());
}

class AgroBookApp extends StatelessWidget {
  const AgroBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProvider()),
        ChangeNotifierProvider(create: (_) => PersonalProvider()),
      ],
      child: MaterialApp(
        title: 'AgroBook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0.5,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
