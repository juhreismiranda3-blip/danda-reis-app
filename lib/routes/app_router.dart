import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/inicio/inicio_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/aluna/agenda_aluna_screen.dart';
import '../presentation/aluna/aluna_home_screen.dart';
import '../presentation/aluna/aula_extra_screen.dart';
import '../presentation/aluna/pagamentos_aluna_screen.dart';
import '../presentation/aluna/perfil_aluna_screen.dart';
import '../presentation/aluna/remarcacao_screen.dart';
import '../presentation/professora/avisos_professora_screen.dart';
import '../presentation/professora/cadastros_screen.dart';
import '../presentation/professora/presenca_screen.dart';
import '../presentation/professora/professora_dashboard_screen.dart';
import '../presentation/professora/relatorios_screen.dart';
import '../providers/providers.dart';

/// Guard central: decide para onde redirecionar com base no estado de
/// login e no tipo de usuário (professora vê só rotas /professora/*,
/// aluna vê só rotas /aluna/*).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(usuarioAtualProvider, (previous, next) => refreshNotifier.ping());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/inicio',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final usuario = ref.read(usuarioAtualProvider).valueOrNull;
      final loc = state.matchedLocation;
      final emInicio = loc == '/inicio';
      final emLogin = loc == '/login';

      if (usuario == null) {
        // Não logado: pode ver a tela de início e o login; qualquer outra
        // rota volta para a tela de início.
        return (emInicio || emLogin) ? null : '/inicio';
      }

      // Já logado: início e login mandam direto para a área do usuário.
      if (emInicio || emLogin) {
        return usuario.isProfessora ? '/professora' : '/aluna';
      }

      final indoParaAreaProfessora = state.matchedLocation.startsWith('/professora');
      final indoParaAreaAluna = state.matchedLocation.startsWith('/aluna');

      if (usuario.isAluna && indoParaAreaProfessora) return '/aluna';
      if (usuario.isProfessora && indoParaAreaAluna) return '/professora';

      return null;
    },
    routes: [
      GoRoute(path: '/inicio', builder: (context, state) => const InicioScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/aluna',
        builder: (context, state) => const AlunaHomeScreen(),
        routes: [
          GoRoute(
            path: 'remarcar/:aulaId',
            builder: (context, state) => RemarcacaoScreen(
              aulaId: state.pathParameters['aulaId']!,
            ),
          ),
          GoRoute(
            path: 'agenda',
            builder: (context, state) => const AgendaAlunaScreen(),
          ),
          GoRoute(
            path: 'aula-extra',
            builder: (context, state) => const AulaExtraScreen(),
          ),
          GoRoute(
            path: 'pagamentos',
            builder: (context, state) => const PagamentosAlunaScreen(),
          ),
          GoRoute(
            path: 'perfil',
            builder: (context, state) => const PerfilAlunaScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/professora',
        builder: (context, state) => const ProfessoraDashboardScreen(),
        routes: [
          GoRoute(
            path: 'presenca',
            builder: (context, state) => const PresencaScreen(),
          ),
          GoRoute(
            path: 'avisos',
            builder: (context, state) => const AvisosProfessoraScreen(),
          ),
          GoRoute(
            path: 'relatorios',
            builder: (context, state) => const RelatoriosScreen(),
          ),
          GoRoute(
            path: 'cadastros',
            builder: (context, state) => const CadastrosScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Ponte simples entre o stream de autenticação do Riverpod e o
/// `refreshListenable` que o GoRouter espera (um Listenable comum).
class _RouterRefreshNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}
