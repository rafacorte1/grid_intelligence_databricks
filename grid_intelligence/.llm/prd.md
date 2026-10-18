# Grid Intelligence — produto e regras de negocio

## Dominio

A Luz do Vale Distribuidora S.A. e uma distribuidora ficticia de energia eletrica,
regulada pela ANEEL. A plataforma conecta continuidade do fornecimento, Perdas Nao
Tecnicas e atendimento ao cliente a decisoes operacionais e financeiras.

Tres dores motivam o projeto: compensacoes por interrupcoes acima dos limites,
energia distribuida e nao faturada e sinais antecipados de reclamacao na ouvidoria
presentes nas transcricoes de atendimento.

Os valores de mais de R$ 1,1 bilhao em compensacoes em 2024 e aproximadamente
R$ 11,5 bilhoes em perdas em 2025, com R$ 7,9 bilhoes repassados a tarifa, sao
contexto fornecido pelo prompt. Nao sao resultados calculados no dataset.

## Glossario

| Termo | Definicao |
|---|---|
| UC — Unidade Consumidora | Ponto de entrega de energia. Um cliente pode ter varias UCs; UC nao e sinonimo de cliente. |
| Conjunto | Subdivisao geografica da concessao e unidade de agregacao do regulador. |
| DEC | Duracao Equivalente de Interrupcao por UC: tempo medio em horas sem fornecimento. |
| FEC | Frequencia Equivalente de Interrupcao por UC: numero medio de interrupcoes. |
| PNT | Perdas Nao Tecnicas. |
| Prioridade de inspecao | Classificacao de quanto uma UC merece visita tecnica: alta, media ou baixa. |

## Regras de negocio

O prompt 00 forneceu dez regras. Os prompts 02 e 04 completaram RN-02, RN-05 e RN-08.
A RN-03 permanece reservada, sem inventar requisitos.

| Regra | Definicao |
|---|---|
| RN-01 | Somente interrupcoes com duracao de 3 minutos ou mais entram em DEC e FEC. Aplicar na transformacao, nunca no relatorio. |
| RN-02 | DEC = soma de duracao_horas vezes qtd_ucs_afetadas dividida pelo total de UCs do conjunto. FEC = soma de qtd_ucs_afetadas dividida pelo mesmo total. |
| RN-03 | Nao fornecida no prompt 00; definicao pendente. |
| RN-04 | DEC e FEC tem uma unica definicao, compartilhada por dashboard, agente e relatorio. |
| RN-05 | A apuracao de continuidade e mensal por conjunto. DEC mensal e acumulado do periodo sao medidas distintas na metric view. |
| RN-06 | Uma UC so e candidata a inspecao quando o consumo cai contra o proprio baseline enquanto a vizinhanca permanece estavel, simultaneamente. |
| RN-07 | A saida e prioridade de inspecao alta, media ou baixa. Nunca usar fraude, furto ou culpado como rotulo de saida em coluna, variavel ou comentario. Mudanca de morador, imovel desocupado, defeito de medidor e erro de leitura tambem explicam quedas. |
| RN-08 | Prioridade de inspecao usa regra explicavel, sem modelo supervisionado sem rotulo confiavel. Cada decisao expoe os dois eixos e os numeros que a sustentam. |
| RN-09 | Mascarar dados pessoais das transcricoes antes de qualquer analise de conteudo. |
| RN-10 | Preservar o texto original identificado com acesso restrito. Protecao na leitura e mascaramento para analise coexistem. |
| RN-11 | A ingestao nao filtra, corrige ou aplica regra de negocio; leituras invalidas sao evidencias sobre o medidor. |
| RN-12 | Todo registro ingerido carrega origem e momento de ingestao. |
| RN-13 | O agente conversacional acessa apenas a camada de negocio. |
| RN-14 | Entidades gold e a metric view levam descricoes em linguagem de negocio. Bronze e silver sao passagem e nao precisam de descricoes. |

## Modelo de informacao

Metadados conferidos nos Parquet locais durante o setup, sem alterar os arquivos.
As chaves indicam o grao logico; defeitos propositais podem gerar duplicatas.

| Base | Grao e volume | Atributos |
|---|---|---|
| unidades_consumidoras | Uma por ponto de entrega; 4.000 registros | id_uc, id_cliente, id_conjunto, nome_conjunto, municipio, bairro, logradouro, classe_consumo, subgrupo_tarifario, tensao_nominal_v, situacao, data_ligacao, possui_medidor_inteligente, consumo_medio_kwh_dia, latitude, longitude, origem, ingerido_em |
| interrupcoes | Um evento de rede; 1.383 registros | id_interrupcao, id_conjunto, inicio, fim, duracao_minutos, tipo, causa, equipamento, qtd_ucs_afetadas, origem, ingerido_em |
| consumo_diario | Uma UC por dia; 5.854.587 registros fisicos | id_uc, data, consumo_kwh, horas_com_leitura, sinal_violacao_medidor, origem, ingerido_em |
| chamados | Uma ligacao; 2.801 registros | id_chamado, id_uc, abertura, canal, nome_solicitante, telefone_solicitante, transcricao, duracao_segundos, origem, ingerido_em |

UCs se relacionam a clientes por id_cliente e a conjuntos por id_conjunto.
Consumo e chamados se relacionam a UCs por id_uc; interrupcoes se relacionam a
conjuntos por id_conjunto. Um evento de conjunto nao informa quais UCs individuais
foram afetadas: qtd_ucs_afetadas representa a abrangencia registrada.

O historico informado cobre quatro anos, com crescimento de 30% ao ano na carga e
sazonalidade de verao no atendimento: dezembro a marco recebe quase o dobro de ligacoes.
Consumo nulo, negativo, fisicamente impossivel, duplicatas e interrupcoes abaixo de
tres minutos sao defeitos propositais, preservados na ingestao.

## Quatro entregas de negocio previstas

1. Continuidade por conjunto: DEC/FEC em definicao unica, para acompanhamento do
   fornecimento e do risco de compensacao. Formulas detalhadas e limites serao
   definidos nas etapas silver e gold.
2. Prioridade de inspecao por UC: cruzar queda contra baseline proprio e estabilidade
   da vizinhanca para orientar visitas tecnicas, sem atribuir culpa.
3. Inteligencia de atendimento: analisar transcricoes mascaradas para identificar
   motivos e sinais de insatisfacao, preservando o original restrito.
4. Visao executiva integrada: reunir continuidade, inspecoes e atendimento na gold,
   consumida por painel AI/BI, copiloto em portugues e relatorio executivo.

## Arquitetura e convencoes

- Isolamento por catalogo, configurado em databricks.yml via ${var.catalog}.
- Schemas raw, bronze, silver e gold declarados uma vez nos recursos do bundle;
  referencias posteriores usam ${resources.schemas.<camada>.name}.
- Volume managed landing na raw; uma pasta por base, inicialmente um Parquet por pasta.
- Bronze preserva os fatos; silver trata numeros e texto; gold publica produtos
  de negocio e a metric view compartilhada de DEC/FEC.
- Os schemas mantem os mesmos nomes em dev e prod, sem prefixo do usuario.
- Tabelas nao repetem o prefixo da camada no nome.
- CLI sempre com --profile grid_intelligence; dev e o destino padrao.
- Textos em portugues do Brasil; nomes de entidades, colunas e arquivos sem acentuacao.
- Sem nome fixo de modelo de IA: usar funcoes ai_* nas etapas que precisarem de IA.
- Sem expectations, CONSTRAINT, COMMENT em bronze/silver, TBLPROPERTIES ou CLUSTER BY,
  salvo se alguma configuracao for indispensavel ao funcionamento.
- Preferir SELECT direto e regras em WHERE; CTE apenas quando simplificar a leitura.
- Comentar apenas decisoes nao obvias, como o limiar regulatorio de tres minutos.
- Nao acrescentar validacoes sem discutir com o usuario.
- Nao sincronizar os Parquet pelo bundle; originais identificados exigem acesso restrito.

## Escopo e sequencia

Nesta etapa: criar os dois catalogos e permissoes do usuario; declarar quatro schemas
 e o volume; validar e publicar somente dev. Prod fica configurado, com catalogo
criado, sem deploy de schemas. Nao criar tabelas, transformacoes, dashboard ou agente.
O upload dos Parquet sera realizado pelo usuario, separadamente.

Sequencia: 01 bronze; 02 silver numeros; 03 silver texto (IA ou regex);
04 gold e metric view; 05 dashboard; 06 agente; 07 relatorio e demonstracao.
