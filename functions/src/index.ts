import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cria a conta de uma aluna (chamado pela professora pelo app).
 *
 * Precisa rodar no servidor porque criar a conta de OUTRA pessoa no
 * Firebase Auth exige privilégios de administrador — não pode ser feito
 * direto no cliente. Cria o usuário no Auth, grava o perfil em
 * `usuarios/{uid}` com tipo 'aluna' e gera um link para a aluna definir a
 * própria senha (que a professora repassa; em produção pode virar e-mail
 * automático de boas-vindas).
 */
export const criarContaAluna = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "É preciso estar logada.");
  }

  const solicitante = await db.collection("usuarios").doc(request.auth.uid).get();
  if (solicitante.data()?.tipo !== "professora") {
    throw new HttpsError(
      "permission-denied",
      "Apenas a professora pode cadastrar alunas."
    );
  }

  const d = request.data ?? {};
  const nome = (d.nome ?? "").toString().trim();
  const email = (d.email ?? "").toString().trim();
  if (!nome || !email) {
    throw new HttpsError("invalid-argument", "Nome e e-mail são obrigatórios.");
  }

  // Senha temporária aleatória — a aluna define a dela pelo link abaixo.
  const senhaTemporaria = Math.random().toString(36).slice(-10) + "aA1!";

  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email,
      password: senhaTemporaria,
      displayName: nome,
    });
  } catch (e) {
    throw new HttpsError(
      "already-exists",
      "Já existe uma conta com esse e-mail (ou o e-mail é inválido)."
    );
  }

  await db.collection("usuarios").doc(userRecord.uid).set({
    nome,
    email,
    telefone: d.telefone ?? null,
    tipo: "aluna",
    turmaId: d.turmaId ?? null,
    diaFixo: d.diaFixo ?? null,
    periodoFixo: d.periodoFixo ?? null,
    pacoteAtualId: d.pacoteAtualId ?? null,
    aulasPorMes: typeof d.aulasPorMes === "number" ? d.aulasPorMes : 4,
    dataInicio: admin.firestore.Timestamp.now(),
  });

  const linkDefinirSenha = await admin.auth().generatePasswordResetLink(email);
  return { uid: userRecord.uid, linkDefinirSenha };
});

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
 * Dispara quando uma aluna recusa a aula e libera a vaga (documento novo em
 * `vagas_ofertadas`). Notifica todas as outras alunas — a primeira que
 * aceitar leva.
 */
export const onVagaOfertada = onDocumentCreated(
  "vagas_ofertadas/{ofertaId}",
  async (event) => {
    const oferta = event.data?.data();
    if (!oferta || oferta.aberta !== true) return;

    const alunas = await db.collection("usuarios").where("tipo", "==", "aluna").get();

    const tokens = alunas.docs
      .filter((d) => d.id !== oferta.origemAlunaId)
      .map((d) => d.data().fcmToken)
      .filter((t): t is string => !!t);

    if (tokens.length === 0) return;

    const data = (oferta.data as admin.firestore.Timestamp).toDate();
    const quando = data.toLocaleDateString("pt-BR", {
      weekday: "long",
      day: "2-digit",
      month: "2-digit",
    });

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "Abriu uma vaga!",
        body: `Vaga em ${quando}. A primeira que aceitar leva — abra o app.`,
      },
    });
  }
);

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
      "Aula amanhã — confirma?",
      "Você tem aula amanhã. Abra o app para confirmar sua presença (ou liberar a vaga)."
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
