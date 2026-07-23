# Como colocar o app no ar 🚀

Guia passo a passo para deixar o **Danda Reis** funcionando de verdade
(conectado ao Firebase). Se você não mexe com programação, dá para seguir
com calma — ou passar este guia para alguém que mexa. Tempo estimado:
**40–60 minutos** na primeira vez.

> Você vai precisar de: um **computador** (Windows ou Mac), uma **conta
> Google** e um **celular** (ou emulador) para testar.

---

## 1. Instalar as ferramentas

1. **Flutter** — siga o instalador oficial: https://docs.flutter.dev/get-started/install
   Depois, no terminal, rode `flutter doctor` e resolva o que ele pedir.
2. **Node.js** (para as Cloud Functions e as CLIs): https://nodejs.org (versão LTS).
3. No terminal:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

## 2. Baixar o projeto

Baixe o código do repositório (botão **Code → Download ZIP** no GitHub) e
descompacte, ou clone:
```bash
git clone https://github.com/juhreismiranda3-blip/danda-reis-app.git
cd danda-reis-app
```

## 3. Criar o projeto no Firebase

1. Acesse https://console.firebase.google.com e clique em **Adicionar projeto**.
2. Dentro do projeto, ative:
   - **Authentication** → método **E-mail/senha** e **Google**.
   - **Firestore Database** → criar (modo produção).
   - **Storage**.
   - **Cloud Messaging** (já vem ativo).
3. As **Cloud Functions** exigem o plano **Blaze** (tem franquia grátis
   generosa; você só paga se passar do limite). Ative em **Faturamento**.

## 4. Conectar o app ao Firebase

Na pasta do projeto:
```bash
flutter pub get
flutterfire configure
```
- Escolha o projeto que você criou. Isso gera o arquivo
  `lib/firebase_options.dart` automaticamente.

Depois, abra `lib/main.dart` e **descomente** duas linhas:
```dart
import 'firebase_options.dart';           // tire as //
...
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,   // tire as //
);
```

## 5. Gerar as pastas de Android/iOS

```bash
flutter create .
```
Isso cria as pastas `android/` e `ios/` sem apagar o código já existente.

## 6. Publicar as regras, os índices e as funções

```bash
# aponte para o seu projeto (troque pelo ID que aparece no console)
firebase use SEU_PROJECT_ID

# regras de segurança + índices do banco
firebase deploy --only firestore:rules,firestore:indexes

# Cloud Functions (notificações, criação de conta da aluna, etc.)
cd functions
npm install
npm run deploy
cd ..
```

## 7. Criar a PRIMEIRA professora (importante!)

O app cria contas de **aluna** pela professora — então a primeira
professora precisa ser criada na mão, uma única vez:

1. No Firebase Console → **Authentication → Users → Add user**: crie com
   e-mail e senha (ex.: o e-mail da Danda).
2. Copie o **UID** que aparece na lista.
3. Vá em **Firestore → Iniciar coleção** → nome `usuarios` → **ID do
   documento = o UID copiado** → adicione os campos:
   - `nome` (string): Danda Reis
   - `email` (string): o mesmo e-mail
   - `tipo` (string): **professora**

Pronto — essa conta entra como professora e já pode cadastrar turmas e alunas.

## 8. Rodar o app

Com o celular conectado (ou um emulador aberto):
```bash
flutter run
```
Para gerar um instalável de Android:
```bash
flutter build apk
```
O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`.

---

## Ordem sugerida para começar a usar

1. Entrar como **professora** → **Cadastros → Turmas**: criar as turmas
   (dia, período, horário, capacidade).
2. **Cadastros → Alunas**: cadastrar as alunas (cada uma recebe um link
   para definir a senha).
3. As alunas entram e já veem agenda, remarcação, pagamentos, etc.

## Dúvidas comuns

- **"As notificações não chegam"** → confira se as Cloud Functions foram
  publicadas (passo 6) e se o celular deu permissão de notificação.
- **"Deu erro de índice no Firestore"** → rode de novo o
  `firebase deploy --only firestore:indexes` e aguarde alguns minutos
  (os índices demoram um pouco para ficarem prontos).
- **Aula extra / reserva** → a lógica hoje roda no app; em produção o ideal
  é mover para Cloud Functions (as regras já preveem isso). Funciona do
  jeito atual para começar.
