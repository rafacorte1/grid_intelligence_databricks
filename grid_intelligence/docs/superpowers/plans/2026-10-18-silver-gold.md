# Silver e gold — plano de implementacao

Objetivo: executar os prompts 02, 03 por regex e 04 sobre a bronze existente.
Arquitetura: um pipeline serverless com SQL parametrizado, seguido por tasks SQL
de governanca e criacao da metric view em um job STANDARD.

- [x] Criar 10_silver_cadastro.sql, 11_silver_interrupcoes.sql e
  12_silver_consumo.sql. Verificar 1.073 eventos, consumo valido sem duplicatas
  e janelas de 30/90 dias ancoradas no maior dia do dado.
- [x] Criar 13_silver_chamados.sql com anonimizacao antes do enriquecimento.
  Verificar 2.801 linhas, CPF/telefone e nomes remanescentes, distribuicoes
  e igualdade de resultados entre duas execucoes.
- [x] Criar os quatro arquivos 20 a 23 da gold. Conferir os 1.073 eventos,
  os dois eixos de prioridade e o grao cliente da saude do atendimento.
- [x] Criar src/sql/governanca_dado_pessoal.sql e metric_view_continuidade.sql,
  configurar warehouse e job no bundle e executar de ponta a ponta.
  Arquivos e recursos publicados. Job completo terminou com sucesso apos reparo
  do DDL da funcao. Grupo atendimento provisionado, tres mascaras aplicadas,
  nova atualizacao preservou o texto e as mascaras. 16 checks passaram.
- [x] Consultar MEASURE para o ultimo mes e varios meses, prioridades por bairro,
  clientes de alto risco e acoes do painel. Registrar resultados e limitacoes.

Os prompts sao a especificacao detalhada. Nao alterar a bronze, nao usar IA,
nao publicar prod e nao criar expectations. Grupo de atendimento deve incluir
a identidade de execucao para que a mascara nao esconda o texto do anonimizador.
