# Danda Reis — App de gestão (corte e costura)

Base do projeto Flutter + Firebase, seguindo Clean Architecture. Este é o
ponto de partida gerado a partir do briefing e das telas já aprovadas com
a cliente — não é o app completo, é a fundação pronta para continuar
construindo junto com o Claude Code.

## O que já está pronto

- Arquitetura de pastas (`core`, `domain`, `data`, `presentation`, `providers`, `routes`)
- Tema visual (paleta rosa/lilás aprovada, Poppins)
- Entidades de domínio: `Usuario`, `Turma`, `Aula` (com máquina de estados), `SolicitacaoRemarcacao`, `Pacote`, `Pagamento`, `Aviso`
- Repositórios completos (interface + implementação Firestore): Auth, Turma, Aula, Pacote, Pagamento, Aviso
- **Fluxo de remarcação completo**: dia → períodos disponíveis → reserva provisória → aprovação da professora
- **Fluxo de aula extra**: escolher período/data com vaga → aula criada → liberada após baixa do pagamento
- **Presença**: professora marca Presente/Faltou por aula do dia
- **Avisos**: professora envia comunicado → dispara notificação (Cloud Function) → aluna vê a lista
- **Pagamentos**: lista da aluna com selo Pago/Pendente/Atrasado; painel da professora com baixa manual
- **Relatórios**: indicadores (alunas, aulas realizadas, faltas, remarcações, extras vendidas, pagamentos pendentes) + gráfico de barras
- Roteamento com guards por tipo de usuário (professora / aluna), incluindo todas as sub-rotas
- Regras de segurança do Firestore (`firestore.rules`)
- **Cloud Functions** (`functions/src/index.ts`):
  - Expiração automática de solicitações de remarcação (a cada hora)
  - Notificação quando a professora aprova/recusa uma remarcação
  - Notificação quando um aviso é criado (para todas as alunas)
  - Lembretes diários (aula amanhã, pagamento vencendo/atrasado)

## Concluído depois da fundação

- **Todas as telas repaginadas** no visual premium (início, login, home da
  aluna, painel da professora, remarcação, aula extra, pagamentos, avisos,
  presença, relatórios)
- **Perfil e Histórico da aluna** (nova tela + aba no menu)
- **Cadastro de turmas e alunas** pela professora (tela `CadastrosScreen`)
- **Criação de conta de aluna** via Cloud Function `criarContaAluna` (cria o
  login no Auth + perfil e devolve link para a aluna definir a senha)
- **Token FCM** persistido no login (`usuarios/{id}.fcmToken`), com regra do
  Firestore permitindo a pessoa atualizar só o próprio token
- **Limite mensal de aulas** com aviso (campo `Usuario.aulasPorMes`)
- **Aula extra somada à mensalidade** + **recibo** de pagamento na área da aluna
- **Reserva atômica de vaga** (contador de ocupação por turma+dia) — evita
  superlotação

## O que ainda falta

1. **Edição/remoção** de turmas e alunas (o cadastro já cria; falta editar)
2. **Receita mensal real** nos relatórios (somar pagamentos com `pagoEm` no mês)
3. **Agenda** da aluna (aba do menu ainda sem tela)
4. Mover as reservas e a cobrança de aula extra para **Cloud Functions** (hoje
   feitas no cliente; as regras do Firestore preveem isso para produção)
5. Testes automatizados (unitários para os repositórios, widget tests das telas)

## Estrutura de pastas atualizada

```
danda_reis_app/
  lib/...            (ver acima)
  functions/         Cloud Functions (TypeScript)
    src/index.ts
  firestore.rules
  pubspec.yaml
```


## Como configurar

1. Instale as dependências:
   ```
   flutter pub get
   ```
2. Crie um projeto no [Firebase Console](https://console.firebase.google.com)
3. Rode o FlutterFire CLI para gerar `firebase_options.dart`:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Descomente a linha `options: DefaultFirebaseOptions.currentPlatform` em `lib/main.dart`
5. No Firebase Console, ative: Authentication (E-mail/senha + Google), Firestore, Storage, Cloud Messaging
6. Publique as regras de segurança:
   ```
   firebase deploy --only firestore:rules
   ```
7. Instale as dependências das Cloud Functions e publique:
   ```
   cd functions
   npm install
   npm run deploy
   ```
8. Rode o app:
   ```
   flutter run
   ```

## Decisões de arquitetura (para referência)

- **Clean Architecture + Repository Pattern**: a camada de apresentação
  (`presentation/`) nunca importa Firebase diretamente — só interfaces de
  `domain/repositories`. Isso facilita testes e troca de backend no futuro.
- **Riverpod**: escolhido pela integração natural com `Stream`/`Future` do
  Firestore via `StreamProvider`/`FutureProvider`, e por permitir DI sem
  boilerplate.
- **Máquina de estados da aula**: evita inconsistências como uma aula
  marcada como falta E remarcada simultaneamente.
- **Reserva provisória na remarcação**: a vaga é ocupada assim que a aluna
  solicita, não quando a professora aprova — evita que duas alunas
  disputem a mesma vaga enquanto aguardam aprovação.
