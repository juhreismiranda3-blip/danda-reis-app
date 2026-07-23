import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Busca o token FCM de uma aluna (armazenado em usuarios/{id}.fcmToken,
 * atualizado pelo app no login — ver TODO no FirebaseAuthRepository do
 * lado Flutter para persistir esse token).
 */
async function enviarNotificacaoParaAluna(alunaId: string, titulo: string, corpo: string) {
  const usuarioDoc = await db.collection("usuarios").doc(alunaId).get();
  const token = usuarioDoc.data()?.fcmToken;
  if (!token) return;

  await messaging.send({
    token,
    notification: { title: titulo, body: corpo },
  });
}

/**
 * Roda a cada hora. Cancela reservas de remarcação cuja professora não
 * respondeu dentro do prazo (24h, ver expiracaoSolicitacao no Flutter).
 * Decisão de arquitetura: isso não pode rodar só no cliente, porque
 * depende de tempo passando mesmo com o app fechado.
 */
export const expirarSolicitacoesRemarcacao = onSchedule("every 60 minutes", async () => {
  const agora = admin.firestore.Timestamp.now();

  const expiradas = await db
    .collection("remarcacoes_pendentes")
    .where("status", "==", "pendente")
    .where("expiraEm", "<", agora)
    .get();

  const batch = db.batch();

  for (const doc of expiradas.docs) {
    const data = doc.data();
    batch.update(doc.ref, { status: "expirada" });

    if (data.novaAulaId) {
      batch.update(db.collection("aulas").doc(data.novaAulaId), {
        status: "cancelada",
      });
    }
  }

  await batch.commit();

  for (const doc of expiradas.docs) {
    const data = doc.data();
    await enviarNotificacaoParaAluna(
      data.alunaId,
      "Solicitação expirada",
      "Sua solicitação de remarcação expirou sem resposta. Tente novamente."
    );
  }
});

/**
 * Dispara quando a professora aprova ou recusa uma remarcação
 * (mudança de status em remarcacoes_pendentes).
 */
export const onRemarcacaoAtualizada = onDocumentUpdated(
  "remarcacoes_pendentes/{solicitacaoId}",
  async (event) => {
    const antes = event.data?.before.data();
    const depois = event.data?.after.data();
    if (!antes || !depois) return;
    if (antes.status === depois.status) return;

    if (depois.status === "aprovada") {
      await enviarNotificacaoParaAluna(
        depois.alunaId,
        "Remarcação aprovada!",
        "Sua aula foi remarcada com sucesso."
      );
    } else if (depois.status === "recusada") {
      await enviarNotificacaoParaAluna(
        depois.alunaId,
        "Remarcação recusada",
        "A professora não aprovou essa remarcação. Escolha outro dia."
      );
    }
  }
);

/**
 * Dispara quando a professora cria um aviso — notifica todas as alunas.
 */
export const onAvisoCriado = onDocumentCreated("avisos/{avisoId}", async (event) => {
  const aviso = event.data?.data();
  if (!aviso) return;

  const alunas = await db.collection("usuarios").where("tipo", "==", "aluna").get();

  const tokens = alunas.docs
    .map((d) => d.data().fcmToken)
    .filter((t): t is string => !!t);

  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title: aviso.titulo, body: aviso.mensagem },
  });
});

/**
 * Roda uma vez por dia. Avisa as alunas que têm aula amanhã e pagamentos
 * vencendo ou atrasados.
 */
export const lembretesDiarios = onSchedule("every day 08:00", async () => {
  const agora = new Date();
  const amanha = new Date(agora);
  amanha.setDate(amanha.getDate() + 1);
  const inicioAmanha = new Date(amanha.getFullYear(), amanha.getMonth(), amanha.getDate());
  const fimAmanha = new Date(inicioAmanha);
  fimAmanha.setDate(fimAmanha.getDate() + 1);

  // Aulas de amanhã
  const aulasAmanha = await db
    .collection("aulas")
    .where("status", "==", "agendada")
    .where("data", ">=", admin.firestore.Timestamp.fromDate(inicioAmanha))
    .where("data", "<", admin.firestore.Timestamp.fromDate(fimAmanha))
    .get();

  for (const doc of aulasAmanha.docs) {
    const aula = doc.data();
    await enviarNotificacaoParaAluna(
      aula.alunaId,
      "Aula amanhã!",
      "Você tem aula amanhã. Não esqueça de trazer seu material."
    );
  }

  // Pagamentos vencendo amanhã ou já atrasados e ainda não pagos
  const pagamentosAbertos = await db.collection("pagamentos").where("pagoEm", "==", null).get();

  for (const doc of pagamentosAbertos.docs) {
    const pagamento = doc.data();
    const vencimento = (pagamento.vencimento as admin.firestore.Timestamp).toDate();

    if (vencimento >= inicioAmanha && vencimento < fimAmanha) {
      await enviarNotificacaoParaAluna(
        pagamento.alunaId,
        "Pagamento vence amanhã",
        `Seu pagamento de R$ ${pagamento.valor} vence amanhã.`
      );
    } else if (vencimento < agora) {
      await enviarNotificacaoParaAluna(
        pagamento.alunaId,
        "Pagamento atrasado",
        `Seu pagamento de R$ ${pagamento.valor} está atrasado.`
      );
    }
  }
});
