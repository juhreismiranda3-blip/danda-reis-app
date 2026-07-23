import '../entities/usuario.dart';

/// Interface de domínio — a camada de apresentação depende apenas disto,
/// nunca diretamente do Firebase (Repository Pattern).
abstract class AuthRepository {
  Stream<Usuario?> get usuarioAtual;

  Future<Usuario> loginComEmailSenha(String email, String senha);
  Future<Usuario> loginComGoogle();
  Future<void> logout();

  /// Usado apenas pela professora, ao cadastrar uma nova aluna.
  /// Cria a conta (via Cloud Function) e devolve um link para a aluna
  /// definir a própria senha.
  Future<NovaContaAluna> criarContaAluna({
    required String nome,
    required String email,
    String? telefone,
    String? turmaId,
    String? diaFixo,
    String? periodoFixo,
    int aulasPorMes = 4,
  });
}

/// Resultado do cadastro de uma nova aluna.
class NovaContaAluna {
  final String uid;

  /// Link que a professora repassa para a aluna definir a senha e entrar.
  final String? linkDefinirSenha;

  const NovaContaAluna({required this.uid, this.linkDefinirSenha});
}
