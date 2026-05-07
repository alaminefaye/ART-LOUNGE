import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  runApp(ArtRestoClientApp(apiClient: apiClient));
}

class ArtRestoClientApp extends StatelessWidget {
  const ArtRestoClientApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthState(apiClient)..init()),
        ChangeNotifierProvider(create: (_) => CartState()),
        Provider(create: (_) => MenuService(apiClient)),
        Provider(create: (_) => OrderService(apiClient)),
      ],
      child: MaterialApp(
        title: 'ART RESTO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
