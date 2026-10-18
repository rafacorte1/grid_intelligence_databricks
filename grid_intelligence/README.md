# Grid Intelligence

Plataforma de dados e IA da Luz do Vale Distribuidora S.A., distribuidora ficticia
 de energia eletrica. O contexto e as regras estao em [.llm/prd.md](.llm/prd.md).

## Setup

Autentique com OAuth no profile escolhido:

```bash
databricks auth login --profile grid_intelligence
```

O bundle isola os ambientes por catalogo: `grid_dev` em dev e `grid_intelligence`
em prod. Os nomes sao configurados em `databricks.yml`. Ambos usam schemas `raw`,
`bronze`, `silver` e `gold`, sem prefixo do usuario.

Crie os catalogos por SQL antes do primeiro deploy para usar o armazenamento padrao:

```bash
databricks experimental aitools tools query --profile grid_intelligence \
  "CREATE CATALOG IF NOT EXISTS grid_dev COMMENT 'Catalogo de desenvolvimento da Grid Intelligence'"
databricks experimental aitools tools query --profile grid_intelligence \
  "CREATE CATALOG IF NOT EXISTS grid_intelligence COMMENT 'Catalogo de producao da Grid Intelligence'"
databricks grants update CATALOG grid_dev \
  --json '{"changes":[{"principal":"rafcorte@gmail.com","add":["ALL_PRIVILEGES"]}]}' \
  --profile grid_intelligence
databricks grants update CATALOG grid_intelligence \
  --json '{"changes":[{"principal":"rafcorte@gmail.com","add":["ALL_PRIVILEGES"]}]}' \
  --profile grid_intelligence
databricks bundle validate --strict -t dev --profile grid_intelligence
databricks bundle deploy -t dev --profile grid_intelligence
```

Os schemas e o volume managed `raw.landing` sao gerenciados por
`resources/grid_schemas.yml`. As transformacoes bronze, silver e gold ficam no
pipeline do mesmo bundle. O deploy descrito aqui publica somente dev.

### Upload dos dados

As quatro bases estao na pasta local `landing/`, cada uma com um unico Parquet.
O upload e separado do deploy. Caminhos para a interface:

```text
/Volumes/grid_dev/raw/landing/unidades_consumidoras/
/Volumes/grid_dev/raw/landing/interrupcoes/
/Volumes/grid_dev/raw/landing/consumo_diario/
/Volumes/grid_dev/raw/landing/chamados/
```

Para enviar as quatro pastas pelo terminal, usando o caminho desta maquina:

```bash
databricks fs cp -r \
  /Users/rafaelcorte/lakehouse-databricks/grid_intelligence/landing \
  dbfs:/Volumes/grid_dev/raw/landing \
  --overwrite --profile grid_intelligence
```

Mantenha uma pasta por base: a bronze lera a pasta, nao o nome do arquivo.
O prefixo `dbfs:` e obrigatorio na CLI mesmo para volumes do Unity Catalog.

### Recomecar do zero — destrutivo

**Nao execute sem confirmar antes.** O comando abaixo remove o catalogo dev,
todos os schemas, tabelas, volumes e arquivos armazenados neles. Nao foi executado
no setup. Depois de uma remocao, o estado do bundle precisa ser reconciliado antes
 de um novo deploy.

```bash
databricks experimental aitools tools query --profile grid_intelligence \
  "DROP CATALOG IF EXISTS grid_dev CASCADE"
```

## Atualizar bronze, silver e gold

O job `grid_intelligence_atualizar` executa o pipeline serverless e depois as tasks
SQL de governanca e metric view. STANDARD atende a atualizacao sem SLA de latencia.

```bash
databricks bundle validate --strict -t dev --profile grid_intelligence
databricks bundle deploy -t dev --profile grid_intelligence
databricks bundle run grid_intelligence_atualizar -t dev --profile grid_intelligence
```

O warehouse SQL e o grupo autorizado sao variaveis `warehouse_id` e
`grupo_atendimento`. Antes de aplicar as mascaras, o grupo de conta precisa existir
e incluir a identidade de execucao do pipeline/job. Sem isso, a task de governanca
interrompe a aplicacao, pois o anonimizador perderia acesso ao original no proximo run.
O grupo de conta `atendimento` foi provisionado com `rafcorte@gmail.com` como membro
e vinculado ao workspace com acesso comum de usuario.
As mascaras sao reaplicadas apos cada pipeline, inclusive apos full refresh.
Enquanto uma tabela e recriada, use somente acesso restrito ao schema bronze.

A silver numerica usa os ultimos 30 dias do dataset e os 90 anteriores como baseline.
Tetos diarios de plausibilidade em kWh: residencial 200, comercial 2.000,
industrial 50.000, rural 3.000 e poder publico 5.000. Classe desconhecida usa 200.
Sao limites de consumo definidos neste projeto para triagem, nao limites regulatorios.
Os parametros de inspecao sao queda de 30% e estabilidade do conjunto de ±10%.

O texto segue a rota deterministica. Nomes diferentes da coluna ou apelidos podem
escapar da substituicao. Ironia, negacao, sinonimos e motivos compostos limitam a
classificacao. Os sinais ficam identificados com `regras_de_texto`.

`gold.saude_cliente` resume o historico de chamados. Reincidencia e tom negativo
sao comparados dentro da mesma janela movel de 30 dias. Para clientes com
UCs em varias regioes, as dimensoes geograficas representam o chamado mais recente.
O painel preserva dias de qualquer origem por FULL OUTER JOIN. Os sinais de
inspecao, que sao uma fotografia atual, aparecem apenas no ultimo dia do dataset.

DEC e FEC sao consultados com `MEASURE()` em `gold.continuidade_metricas`.
DEC e media mensal no recorte, DEC Acumulado soma os meses. O total de UCs e uma
base media mensal. Conjuntos/meses sem evento aparecem com zero na continuidade
para preservar o denominador de UCs tambem nesses meses.
Os asserts dos criterios de aceite estao em `tests/aceite_silver_gold.sql`.
Os testes de aplicacao e leitura das mascaras estao em `tests/aceite_governanca.sql`.

## Proximas etapas

Siga os [prompts](prompts/README.md) em ordem: bronze, silver numeros, silver texto,
gold, dashboard, agente e relatorio. A RN-03 continua pendente no PRD.
