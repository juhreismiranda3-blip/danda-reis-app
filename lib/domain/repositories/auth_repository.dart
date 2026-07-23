import '../entities/usuario.dart';

/// Interface de domínio — a camada de apresentação depende apenas disto,
/// nunca diretamente do Firebase (Repository Pattern).
abstract class AuthRepository {
  Stream<Usuario?> get usuarioAtual;

  Future<Usuario> loginComEmailSenha(String email, String senha);
  Future<Usuario> loginComGoogle();
  Future<void> logout();

  /// Usado apenas pela professora, ao cadastrar uma nova aluna.
  /// Cria a conta e envia um convite/senha temporária por e-mail.
  Future<void> criarContaAluna({
    required String nome,
    required String email,
  });
}
