import '../entities/pacote.dart';

abstract class PacoteRepository {
  Stream<List<Pacote>> get todosPacotes;
  Future<void> criarPacote(Pacote pacote);
  Future<void> removerPacote(String pacoteId);

  /// Contrata um pacote para uma aluna (professora faz isso).
  Future<void> contratarPacote({
    required String alunaId,
    required String pacoteId,
    required DateTime validoAte,
  });

  /// Saldo calculado: aulas do pacote menos aulas já usadas (status
  /// concluida, falta ou agendada com origem 'pacote') no período vigente.
  Stream<SaldoPacote> saldoDe(String alunaId);
}
