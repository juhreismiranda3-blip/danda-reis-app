import '../entities/aviso.dart';

abstract class AvisoRepository {
  Stream<List<Aviso>> get avisosRecentes;

  /// Ao criar, uma Cloud Function dispara a notificação push para
  /// todas as alunas ativas (ver functions/src/index.ts).
  Future<void> enviarAviso({required String titulo, required String mensagem});
}
