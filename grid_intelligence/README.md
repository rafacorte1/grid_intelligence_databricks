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
`resources/grid_schemas.yml`. O setup nao publica prod nem cria transformacoes.

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

## Proximas etapas

Siga os [prompts](prompts/README.md) em ordem: bronze, silver numeros, silver texto,
gold, dashboard, agente e relatorio. As regras RN-02, RN-03, RN-05 e RN-08 nao foram
 definidas no prompt inicial e estao registradas como pendentes no PRD.
