# LarQuest

**Pequenas tarefas. Grandes transformações.**

Aplicativo Flutter Web com Supabase Auth/PostgreSQL, missões domésticas e casa 2D decorável. Interface em português, com verde suave, cartões pastel, cantos arredondados e mascote vetorial animado. O projeto é código-fonte para executar e hospedar; não contém um site já publicado.

## Comece aqui

1. Instale Flutter estável **3.35 ou superior** e Chrome. Confira com `flutter doctor`.
2. Crie um projeto **novo e exclusivo** no Supabase. Não execute o SQL em um banco de outro aplicativo: nomes como `profiles` podem conflitar.
3. Abra **SQL Editor → New query**, cole todo o conteúdo de `supabase/setup.sql` e execute **uma vez**. O script inclui tabelas, políticas, funções, trigger, 16 missões, cinco conquistas e 12 produtos.
4. No painel do projeto, copie a **Project URL** e uma **publishable key** (ou chave legada `anon`). Consulte o diálogo Connect ou as configurações de API do projeto.
5. Copie `config.example.json` para `config.json` e substitua os dois valores. Não use `service_role`, chave secret nem senha do banco.
6. Em Authentication, habilite o provedor de e-mail. Para uso normal, mantenha a confirmação de e-mail ativa. Para apresentação escolar, você pode desativá-la conscientemente para criar contas sem aguardar o e-mail.
7. Em Authentication → URL Configuration, configure a Site URL e URLs de redirecionamento com `http://localhost:7357` e, quando publicado, a URL real do aplicativo. Se a confirmação estiver ativa, confirme o cadastro no e-mail antes de entrar.
8. No terminal, dentro da pasta `LarQuest`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port 7357 --dart-define-from-file=config.json
```

No Windows, abra a pasta no VS Code e use o terminal integrado. Chrome é o navegador alvo. Não é necessário backend Node para executar o app.

## Configuração do Supabase incluída

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_ANON_KEY": "SUA_CHAVE_PUBLICA_PUBLISHABLE_OU_ANON"
}
```

Não foi vinculado um projeto real: a URL e a chave da sua conta precisam ser preenchidas. O app apresenta uma tela de orientação se estiver sem configuração. Não há autenticação simulada nem ranking fictício.

## O que funciona no código

- Splash com mascote desenhado em CustomPainter, animação de entrada e direcionamento por sessão.
- Cadastro, login, sessão persistida pelo SDK e logout com GoRouter protegendo as telas internas.
- Central de missões com saudação, XP, moedas, nível, total de tarefas, destaque e filtros por cômodo/status.
- Detalhes com categoria, dificuldade, instruções, início e confirmação de conclusão.
- Recompensa única por missão/usuário; transação no banco e bloqueio do perfil contra compras/conclusões concorrentes.
- Conquistas calculadas pelo banco: primeira tarefa, cinco tarefas, três dias distintos, três tarefas de reciclagem e todas as tarefas.
- Ranking calculado no PostgreSQL: top 100 e posição própria mesmo fora do top 100. Os três primeiros recebem medalhas. Não expõe e-mail nem moedas.
- Planta 2D com sala, cozinha, quarto e banheiro; seleção do cômodo e edição do piso em detalhe.
- Loja com compra confirmada, validação de saldo, inventário e decoração persistidos. Escolha um item e toque no piso para colocá-lo ou movê-lo; × guarda o item.
- Perfil com apelido editável, e-mail, progresso, conquistas e quatro cores do mascote; três precisam ser compradas.
- Estados de carregamento, erro e lista vazia, com recarga manual e mensagens das operações.

A mobília é uma representação 2D feita com ícones vetoriais do Material, e o mascote é desenhado no Flutter. Não usa sprites externos. A casa não tem movimentação de personagem nem colisões; a interação é por seleção e posicionamento. Cada item pode ser comprado uma vez por conta e colocado no cômodo indicado.

As tarefas são únicas e não reiniciam diariamente. Isso atende à regra de não repetir a recompensa da mesma missão. A conquista de consistência usa três datas diferentes no fuso America/Sao_Paulo, sem exigir dias consecutivos. Não foram adicionados gráficos, missões diárias ou desafios criados pelos usuários.

## XP e moedas

Uma tarefa de 25 pontos concede **25 XP + 25 moedas**. XP determina o ranking e nível (`1 + XP ~/ 200`); moedas são gastas na loja. Compras nunca reduzem XP. O catálogo inicial soma 485 XP/moedas; escolha como gastá-las, pois não é possível comprar tudo com as missões iniciais. Novos desafios podem ser cadastrados pelo administrador do banco.

## Arquitetura para a apresentação

| Arquivo | Responsabilidade |
|---|---|
| `lib/main.dart` | Inicialização, tema, splash e GoRouter |
| `lib/store.dart` | Sessão observável, consultas e comandos RPC |
| `lib/screens.dart` | Login, home, detalhes, conquistas, ranking, perfil, loja e casa |
| `lib/widgets.dart` | MissionCard, ProgressCard, AchievementBadge, Mascot, SoftCard e Furniture |
| `supabase/setup.sql` | Estrutura completa, dados iniciais e regras de segurança |

Os widgets personalizados recebem dados por parâmetros. As rotas principais são `/`, `/mission/:id`, `/house`, `/shop`, `/achievements`, `/ranking` e `/profile`. O parâmetro da missão é resolvido a partir do catálogo carregado do banco. Sem sessão, o roteador redireciona para `/login`.

`profiles.id` referencia `auth.users.id`; as tabelas de progresso, inventário, decoração e conquistas usam essa identidade. Chaves compostas impedem registros duplicados. RLS permite apenas leitura de dados próprios, além dos catálogos. O cliente não pode inserir, atualizar, apagar ou truncar tabelas diretamente.

A RPC pública `game_action` recebe a ação e os identificadores, nunca os pontos ou o usuário de destino. O código privilegiado fica no schema privado `larquest_private`, que **não deve ser adicionado aos schemas expostos da Data API**. Ele usa `auth.uid()`, search_path vazio e bloqueio transacional do perfil. O ranking é uma divulgação deliberada e limitada de posição, ID, apelido e XP. Apelidos são públicos entre jogadores autenticados.

## Compilar e publicar

```bash
flutter build web --release --dart-define-from-file=config.json
```

Publique o conteúdo de `build/web` em um serviço de hospedagem estática HTTPS. O GoRouter usa URLs com hash por padrão, evitando a necessidade de regras especiais para refresh das rotas. Configure a URL final no Supabase antes de testar confirmação de e-mail. A chave pública fica no bundle do navegador por projeto; as permissões são protegidas pelo banco.

As dependências diretas estão fixadas no pubspec. A primeira execução de `flutter pub get` gerará `pubspec.lock`; mantenha esse arquivo no seu repositório para fixar também as dependências transitivas. Nenhum lockfile Flutter foi inventado neste pacote.

## Verificação e limites desta entrega

O ambiente de criação não tinha Flutter/Dart, e os downloads do SDK não ficaram disponíveis. Portanto **flutter analyze, flutter test, build web e validação visual no navegador não foram executados**. Os quatro arquivos Dart foram analisados por parser de sintaxe. Os testes de widgets estão fornecidos para executar localmente, mas ainda não foram executados.

O SQL foi executado em PostgreSQL embarcado PGlite, com simulação local de `auth.users`, `auth.uid()` e papéis. Isso verifica as transações e políticas do SQL, mas não substitui o teste do Supabase Auth e PostgREST no seu projeto real. Veja `verification/RESULTADOS.md`.

Para repetir os testes de banco sem acessar uma conta Supabase:

```bash
cd verification
npm ci
npm test
```

Requer Node.js 20 ou superior. Esses testes criam um banco descartável em memória, sem usar credenciais.

## Roteiro de demonstração

1. Crie uma conta e confirme o e-mail, se exigido.
2. Entre, abra “Cada coisa em seu lugar” e clique em iniciar.
3. Realize a tarefa, confirme a conclusão e veja 25 XP, 25 moedas e a primeira conquista.
4. Tente reabrir a missão: ela permanece concluída, sem nova recompensa.
5. Compre a planta da sala por 25 moedas: o saldo vai a zero e o XP continua 25.
6. Visite Minha casa, escolha Sala, selecione a planta e toque no piso.
7. Consulte conquistas, ranking e perfil.
8. Saia e entre novamente: XP, compra e posição da mobília vêm do banco.
9. Crie outra conta: o progresso e inventário dela começam separados.

## Se algo falhar

- **Tela pede configuração:** confira config.json e passe `--dart-define-from-file=config.json` tanto ao executar quanto ao compilar.
- **E-mail não confirmado:** confirme o link ou ajuste a configuração de Auth para o ambiente de apresentação.
- **Tabela/função ausente:** execute setup.sql por inteiro em um projeto novo.
- **Permissão negada:** confira que a sessão está ativa, public está exposto na Data API e o script terminou em COMMIT.
- **Erro de cadastro:** verifique senha com pelo menos oito caracteres, e-mail válido, confirmação e limites de envio do provedor.

Referências oficiais consultadas: https://supabase.com/docs/reference/dart/auth-signup e https://supabase.com/docs/reference/dart/rpc .
