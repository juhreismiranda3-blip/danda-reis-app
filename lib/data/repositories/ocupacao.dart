/// Convenção do contador de ocupação de turmas.
///
/// Para garantir que nunca haja superlotação — mesmo se duas alunas
/// confirmarem a última vaga no mesmo instante — a ocupação de cada
/// turma em cada dia é mantida num documento próprio na coleção
/// `ocupacao`, lido e atualizado dentro de uma transação do Firestore.
/// Como o Firestore serializa transações que tocam o mesmo documento,
/// uma reserva espera a outra e a checagem de capacidade é atômica.
///
/// O `ocupadas` reflete quantas aulas estão `agendada` naquela turma+dia.
/// Toda transição que cria/encerra uma aula agendada ajusta esse contador.
library;

/// ID determinístico do documento de ocupação para uma turma num dia.
String ocupacaoDocId(String turmaId, DateTime dia) {
  final y = dia.year.toString().padLeft(4, '0');
  final m = dia.month.toString().padLeft(2, '0');
  final d = dia.day.toString().padLeft(2, '0');
  return '${turmaId}__$y$m$d';
}

/// Início do dia (00:00), usado como chave e valor de `data` no contador.
DateTime inicioDoDia(DateTime dia) => DateTime(dia.year, dia.month, dia.day);
