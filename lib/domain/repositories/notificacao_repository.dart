/// Cuida das notificações push (FCM). A camada de apresentação depende só
/// desta interface, nunca do Firebase Messaging diretamente.
abstract class NotificacaoRepository {
  /// Pede permissão de notificação (se ainda não concedida) e salva o token
  /// FCM no perfil da pessoa (usuarios/{id}.fcmToken), atualizando sozinho
  /// quando o token mudar. É o que faz as Cloud Functions conseguirem
  /// notificar a aluna.
  Future<void> registrarToken(String usuarioId);
}
