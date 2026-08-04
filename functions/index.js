/**
 * Central de notificações do Danda Reis.
 * Dispara notificações (push) quando a professora envia um aviso
 * ou quando abre uma vaga (aluna cancela). Roda com o app fechado.
 */
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
setGlobalOptions({region: "southamerica-east1", maxInstances: 5});

const APP_URL = "https://juhreismiranda3-blip.github.io/danda-reis-app/";

exports.notificar = onDocumentWritten("app/estado", async (event) => {
  const before = event.data && event.data.before && event.data.before.exists ? event.data.before.data() : {};
  const after = event.data && event.data.after && event.data.after.exists ? event.data.after.data() : {};

  const antesAvisos = new Set((before.avisos || []).map((a) => a.id));
  const antesOfertas = new Set((before.ofertas || []).map((o) => o.id));
  const novosAvisos = (after.avisos || []).filter((a) => !antesAvisos.has(a.id));
  const novasOfertas = (after.ofertas || []).filter((o) => o.aberta && !antesOfertas.has(o.id));

  if (!novosAvisos.length && !novasOfertas.length) return;

  const snap = await db.collection("pushTokens").where("mode", "==", "aluna").get();
  const tokens = [];
  snap.forEach((d) => tokens.push({token: d.id, alunaId: d.get("alunaId") || ""}));
  if (!tokens.length) return;

  const mensagens = [];
  for (const av of novosAvisos) {
    for (const t of tokens) {
      mensagens.push(montar(t.token, "📣 " + (av.titulo || "Aviso"), av.msg || ""));
    }
  }
  for (const of of novasOfertas) {
    for (const t of tokens) {
      if (t.alunaId && t.alunaId === of.origem) continue;
      mensagens.push(montar(t.token, "🎀 Abriu uma vaga!", "Toque para ver e garantir a sua."));
    }
  }
  await enviar(mensagens);
});

function montar(token, title, body) {
  return {
    token,
    data: {title, body, link: APP_URL, icon: APP_URL + "icon.png"},
  };
}

async function enviar(mensagens) {
  const M = getMessaging();
  const invalidos = [];
  for (let i = 0; i < mensagens.length; i += 450) {
    const lote = mensagens.slice(i, i + 450);
    const resp = await M.sendEach(lote);
    resp.responses.forEach((r, idx) => {
      if (!r.success) {
        const code = (r.error && r.error.code) || "";
        if (code.includes("registration-token-not-registered") ||
            code.includes("invalid-registration-token") ||
            code.includes("invalid-argument")) {
          invalidos.push(lote[idx].token);
        }
      }
    });
  }
  await Promise.all(invalidos.map((t) => db.collection("pushTokens").doc(t).delete().catch(() => {})));
}
