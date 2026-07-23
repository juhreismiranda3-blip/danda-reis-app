import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'routes/app_router.dart';
// Gerado automaticamente pelo `flutterfire configure` — ver README.
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(const ProviderScope(child: DandaReisApp()));
}

class DandaReisApp extends ConsumerWidget {
  const DandaReisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Quando a pessoa loga (ou o login é restaurado ao abrir o app),
    // registra/atualiza o token FCM no perfil dela — necessário para as
    // Cloud Functions conseguirem enviar as notificações.
    ref.listen(usuarioAtualProvider, (anterior, atual) {
      final usuario = atual.valueOrNull;
      if (usuario != null) {
        ref.read(notificacaoRepositoryProvider).registrarToken(usuario.id);
      }
    });

    return MaterialApp.router(
      title: 'Danda Reis Corte e Costura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
