# Verificação — 26/10/2026

## Executado

- Parser tree-sitter-dart: quatro arquivos de produção sem erros de sintaxe.
- SQL inteiro executado em PostgreSQL embarcado PGlite 0.5.12 com esquema Auth e papéis simulados.
- 21 verificações aprovadas no teste `security.mjs`:
  1. RLS do perfil e crédito da recompensa.
  2. Recusa de recompensa duplicada.
  3. Exigência de início antes da conclusão.
  4. Recusa de alteração direta de XP.
  5. Recusa de inserção direta no inventário.
  6. Recusa de compra sem saldo.
  7. Compra desconta moedas e preserva XP.
  8. Recusa de compra duplicada.
  9. Exigência de posse para decorar.
  10. Compatibilidade do item com o cômodo.
  11. Persistência do posicionamento.
  12. Cor bloqueada sem compra.
  13. Primeira conquista automática.
  14. Ranking real entre duas contas.
  15. Isolamento da decoração.
  16. Isolamento das missões.
  17. Cinco conquistas, incluindo três dias distintos e reciclagem.
  18. Soma final de 485 XP.
  19. Compra e aplicação de cor.
  20. Recusa de TRUNCATE pelo cliente.
  21. RPC negada ao papel anon.

O teste de consistência ajusta duas datas como administrador apenas no banco em memória, como fixtures. Nenhuma conta ou banco remoto foi acessado.

## Não executado

- flutter pub get, analyze, test ou build: SDK indisponível neste ambiente.
- Testes visuais de responsividade/animação no navegador.
- Fluxo real de Supabase Auth, confirmação de e-mail, PostgREST e persistência de sessão no navegador.
- Teste de concorrência com conexões independentes. O SQL usa bloqueio por perfil; o harness local testou as regras sequenciais.

Execute os comandos do README e o roteiro de demonstração antes da apresentação. Os três testes de widgets fornecidos ainda precisam ser executados com Flutter.
