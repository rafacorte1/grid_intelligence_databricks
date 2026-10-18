# Resultado dos prompts 02, 03 regex e 04

Ambiente: grid_dev. Perfil: grid_intelligence. Data: 18/10/2026.

Pipeline serverless, governanca e metric view publicados e executados em dev. Grupo de atendimento provisionado e tres mascaras aplicadas. Uma nova atualizacao com as mascaras ativas preservou os resultados da silver.

## Silver numerica

| bronze | descartadas | pct_descartadas |
| --- | --- | --- |
| 1383 | 310 | 22.4 |

| bronze | nulas | negativas | sem_cadastro | descartadas | validas_antes_deduplicacao | duplicatas | silver |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 5854587 | 23478 | 8799 | 0 | 36811 | 5817776 | 14502 | 5803274 |

Das 36.811 leituras descartadas, 23.478 eram nulas, 8.799 negativas e 4.534 excediam os tetos por classe. Mais 14.502 eram duplicatas validas. Restaram 5.803.274 chaves UC/dia.

Janelas: recente 02/07/2026 a 31/07/2026, baseline 03/04/2026 a 01/07/2026. A variacao e percentual.

| id_conjunto | variacao_pct | media_baseline | media_recente |
| --- | --- | --- | --- |
| CPQ-01 | 1.2425 | 74.36485586673095 | 75.28887378011588 |
| CPQ-02 | 4.827 | 53.574677806197336 | 56.16072585578408 |
| IDT-01 | 1.9042 | 98.94343161779777 | 100.82756022346362 |
| SMR-01 | 3.9809 | 306.99458237127806 | 319.21574726053876 |
| VLH-01 | 3.0028 | 59.816572274572586 | 61.61271844280606 |
| VRU-01 | 1.7315 | 65.82278369824252 | 66.96247807874904 |

## Texto deterministico

| motivo | sentimento | chamados |
| --- | --- | --- |
| duvida_cadastral | negative | 86 |
| duvida_cadastral | neutral | 349 |
| duvida_cadastral | positive | 450 |
| erro_leitura | neutral | 169 |
| erro_leitura | positive | 139 |
| falta_energia | negative | 109 |
| falta_energia | neutral | 135 |
| falta_energia | positive | 120 |
| fatura_alta | neutral | 122 |
| fatura_alta | positive | 107 |
| oscilacao_tensao | neutral | 130 |
| oscilacao_tensao | positive | 97 |
| poste_avariado | neutral | 74 |
| poste_avariado | positive | 65 |
| religacao | neutral | 131 |
| religacao | positive | 116 |
| religacao_urgente | neutral | 195 |
| religacao_urgente | positive | 207 |

Nos 2.801 chamados: zero CPF formatado e zero telefone com DDD sobreviventes. A busca por primeiro nome encontra 11 substrings e uma palavra inteira. A palavra inteira e Pedro em "Sitio Sao Pedro" (CHM001569), um lugar. A apresentacao do solicitante foi corretamente substituida. A busca por nome isolada tem falsos positivos e nao prova anonimizacao universal.

Exemplo CHM000003: o nome, o CPF e as duas ocorrencias de telefone foram substituidos por [MASCARADO], preservando a reclamacao sobre oscilacao de tensao. O original foi consultado lado a lado durante a verificacao e nao e copiado para este relatorio.

## Continuidade — julho de 2026

| Codigo do Conjunto | Conjunto | dec_horas | fec |
| --- | --- | --- | --- |
| CPQ-01 | Campinas Centro | 1.2473371212121214 | 0.42613636363636365 |
| CPQ-02 | Campinas Norte | 0.397863125 | 0.41375 |
| IDT-01 | Indaiatuba | 0.12406666666666666 | 0.31833333333333336 |
| SMR-01 | Sumare Industrial | 0.0320375 | 0.075 |
| VLH-01 | Valinhos | 0.2121622222222222 | 0.38666666666666666 |
| VRU-01 | Vale Rural | 0.37206583333333326 | 0.485 |

## Comparacao mensal e acumulado nos 48 meses

| Codigo do Conjunto | dec_mensal | dec_acumulado | total_ucs |
| --- | --- | --- | --- |
| CPQ-01 | 0.09948873500631317 | 4.775459280303032 | 880.0 |
| CPQ-02 | 0.12932742621527776 | 6.2077164583333335 | 800.0 |
| IDT-01 | 0.15016447337962963 | 7.207894722222222 | 600.0 |
| SMR-01 | 0.10856235977564106 | 5.210993269230771 | 520.0 |
| VLH-01 | 0.12278734953703702 | 5.893792777777777 | 600.0 |
| VRU-01 | 0.22630600115740743 | 10.862688055555555 | 600.0 |

A base completa tem 288 linhas: seis conjuntos por 48 meses. Meses sem evento recebem zero e preservam o denominador. A soma dos eventos na gold e 1.073. MEASURE(`Total de UCs`) sem agrupamento devolveu 4.000.

## Clientes em risco alto de ouvidoria

A saude do cliente resume o historico completo, com reincidencia medida em janelas moveis de 30 dias. Sao 1.519 clientes, 84 de risco alto e 498 de risco medio. Um cliente e reincidente.

| id_cliente | id_conjunto | bairro | qtd_chamados | qtd_ucs_com_chamado | qtd_mencoes_ouvidoria | qtd_chamados_negativos | motivo_predominante | risco_ouvidoria |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CLI003104 | SMR-01 | Distrito Industrial | 5 | 2 | 2 | 2 | duvida_cadastral | alto |
| CLI002196 | CPQ-01 | Cambui | 2 | 2 | 2 | 2 | duvida_cadastral | alto |
| CLI001895 | VLH-01 | Macuco | 8 | 4 | 1 | 1 | duvida_cadastral | alto |
| CLI002306 | IDT-01 | Cidade Nova | 7 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001597 | SMR-01 | Nova Veneza | 6 | 3 | 1 | 1 | duvida_cadastral | alto |
| CLI000396 | CPQ-01 | Vila Industrial | 5 | 3 | 1 | 1 | duvida_cadastral | alto |
| CLI000582 | CPQ-01 | Bosque | 5 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001648 | SMR-01 | Jardim Bela Vista | 5 | 2 | 1 | 2 | duvida_cadastral | alto |
| CLI002822 | SMR-01 | Picerno | 5 | 3 | 1 | 1 | duvida_cadastral | alto |
| CLI000048 | VLH-01 | Macuco | 4 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI000932 | CPQ-02 | Jardim Eulina | 4 | 2 | 1 | 1 | erro_leitura | alto |
| CLI001304 | VLH-01 | Centro | 4 | 2 | 1 | 1 | falta_energia | alto |
| CLI001464 | CPQ-01 | Vila Industrial | 4 | 2 | 1 | 1 | religacao_urgente | alto |
| CLI003206 | CPQ-01 | Botafogo | 4 | 2 | 1 | 1 | falta_energia | alto |
| CLI000176 | CPQ-02 | Jardim Aurora | 3 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000238 | CPQ-02 | Jardim Eulina | 3 | 3 | 1 | 1 | duvida_cadastral | alto |
| CLI000615 | VLH-01 | Macuco | 3 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001147 | VRU-01 | Bairro dos Pires | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001168 | SMR-01 | Nova Veneza | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001189 | SMR-01 | Nova Veneza | 3 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001225 | VRU-01 | Recanto | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001824 | IDT-01 | Itaici | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002343 | IDT-01 | Cidade Nova | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002391 | CPQ-01 | Bosque | 3 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002705 | CPQ-02 | Jardim Eulina | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002708 | CPQ-02 | Santa Genebra | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002744 | IDT-01 | Vila Furlan | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002987 | VLH-01 | Vila Sao Jose | 3 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI003010 | VRU-01 | Sitio Sao Pedro | 3 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003360 | CPQ-02 | Santa Genebra | 3 | 1 | 1 | 1 | oscilacao_tensao | alto |
| CLI000228 | CPQ-02 | Mansoes | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000309 | CPQ-01 | Cambui | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI000331 | CPQ-02 | Jardim Eulina | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI000692 | VLH-01 | Capuava | 2 | 1 | 1 | 2 | duvida_cadastral | alto |
| CLI000795 | VRU-01 | Recanto | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000822 | CPQ-02 | Jardim Aurora | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI000866 | CPQ-02 | Village | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI000888 | CPQ-01 | Cambui | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000992 | CPQ-01 | Botafogo | 2 | 1 | 1 | 2 | duvida_cadastral | alto |
| CLI001030 | CPQ-02 | Jardim Aurora | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001104 | CPQ-01 | Guanabara | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001163 | CPQ-02 | Barao Geraldo | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001370 | VRU-01 | Recanto | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001651 | SMR-01 | Picerno | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001755 | CPQ-01 | Centro | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001866 | SMR-01 | Nova Veneza | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001953 | VRU-01 | Colonia | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI001993 | CPQ-02 | Jardim Eulina | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002063 | CPQ-01 | Centro | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002064 | CPQ-02 | Mansoes | 2 | 2 | 1 | 2 | duvida_cadastral | alto |
| CLI002072 | CPQ-02 | Barao Geraldo | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002116 | SMR-01 | Matao | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002198 | SMR-01 | Nova Veneza | 2 | 2 | 1 | 2 | duvida_cadastral | alto |
| CLI002257 | IDT-01 | Vila Furlan | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002356 | CPQ-02 | Jardim Aurora | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002485 | VRU-01 | Estrada do Moinho | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002501 | CPQ-01 | Bosque | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI002601 | CPQ-01 | Botafogo | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002787 | VLH-01 | Macuco | 2 | 2 | 1 | 2 | duvida_cadastral | alto |
| CLI002794 | SMR-01 | Picerno | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002984 | CPQ-02 | Barao Geraldo | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003088 | IDT-01 | Cidade Nova | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003233 | SMR-01 | Jardim Bela Vista | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003242 | SMR-01 | Picerno | 2 | 2 | 1 | 1 | duvida_cadastral | alto |
| CLI003335 | CPQ-01 | Guanabara | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003352 | CPQ-02 | Santa Genebra | 2 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000041 | CPQ-01 | Bosque | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000129 | IDT-01 | nao informado | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000211 | VRU-01 | Bairro dos Pires | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000214 | CPQ-02 | Mansoes | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000277 | SMR-01 | Distrito Industrial | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000326 | CPQ-02 | Jardim Aurora | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000670 | VRU-01 | Boa Vista | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI000719 | CPQ-02 | Village | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001327 | SMR-01 | Jardim Bela Vista | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001522 | CPQ-02 | Mansoes | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001622 | CPQ-01 | Cambui | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI001639 | SMR-01 | Distrito Industrial | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002350 | CPQ-01 | Cambui | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002467 | VRU-01 | Estrada do Moinho | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI002706 | CPQ-01 | Bosque | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003199 | IDT-01 | Itaici | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003330 | CPQ-01 | Guanabara | 1 | 1 | 1 | 1 | duvida_cadastral | alto |
| CLI003440 | CPQ-01 | Centro | 1 | 1 | 1 | 1 | duvida_cadastral | alto |

## Visitas tecnicas prioritarias

| id_conjunto | bairro | ucs_prioridade_alta |
| --- | --- | --- |
| CPQ-02 | Jardim Aurora | 20 |
| VLH-01 | Ortizes | 1 |

21 UCs em prioridade alta. Todas satisfazem queda individual de ao menos 30%, variacao absoluta do conjunto de ate 10% e sinal recente no medidor.

## Painel do dia mais recente com interrupcoes — 30/07/2026

| Conjunto | Interrupcoes | Chamados | Acao recomendada |
| --- | --- | --- | --- |
| CPQ-01 | 1 | 6 | Mobilizar equipe para continuidade do fornecimento |
| CPQ-02 | 1 | 6 | Mobilizar equipe para continuidade do fornecimento |
| IDT-01 | 0 | 0 | Acompanhar operacao |
| SMR-01 | 0 | 1 | Acompanhar operacao |
| VLH-01 | 2 | 4 | Mobilizar equipe para continuidade do fornecimento |
| VRU-01 | 0 | 0 | Acompanhar operacao |

## Painel do ultimo dia do dataset

| data | id_conjunto | qtd_interrupcoes | qtd_chamados | qtd_chamados_risco_saude | qtd_mencoes_ouvidoria | ucs_prioridade_alta | acao_recomendada |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-07-31 | CPQ-01 | 0 | 3 | 0 | 0 | 0 | Acompanhar operacao |
| 2026-07-31 | CPQ-02 | 0 | 2 | 0 | 0 | 20 | Programar visitas tecnicas prioritarias |
| 2026-07-31 | IDT-01 | 0 | 0 | 0 | 0 | 0 | Acompanhar operacao |
| 2026-07-31 | SMR-01 | 0 | 0 | 0 | 0 | 0 | Acompanhar operacao |
| 2026-07-31 | VLH-01 | 0 | 1 | 1 | 0 | 1 | Acionar atendimento prioritario por risco a saude |
| 2026-07-31 | VRU-01 | 0 | 0 | 0 | 0 | 0 | Acompanhar operacao |

Em dias historicos, a prioridade de inspecao atual nao e repetida artificialmente. A fotografia de inspecao aparece em 31/07/2026.

## Execucoes e determinismo

[Execucao inicial parcial do job](https://dbc-1a1f7eb6-688b.cloud.databricks.com/jobs/607282318606996/runs/946174998409047): 398,080 segundos (6 min 38 s), incluindo agendamento e inicializacao no modo STANDARD. Task pipeline: 393 segundos. Task metric_view: 3 segundos. Task governanca: explicitamente nao selecionada por falta do grupo autorizado.

Duas execucoes com o cadastro completo produziram 2.801 linhas e a mesma soma de xxhash64 de todas as colunas: `450080987629941661953`. A comparacao independe da ordem das linhas.

## Verificacao

16 consultas de assert em tests/aceite_silver_gold.sql e tests/aceite_governanca.sql passaram apos a atualizacao com mascaras ativas. Incluem volume, validade e unicidade de consumo, RN-01, metodos de texto, dois eixos, grao de cliente, grao do painel, cobertura mensal e denominadores.

A primeira execucao exigiu habilitar timestampNtz nas materialized views que preservam timestamps sem fuso. A primeira criacao do cadastro tambem exigiu uma atualizacao seguinte para propagar seu conteudo as views dependentes.

## Governanca concluida

- Grupo de conta: `atendimento`, ID `83423321031186`.
- Membro: `rafcorte@gmail.com`, ID `71656168973931`.
- Grupo vinculado ao workspace com permissao `USER`. Associacao reconhecida por `is_account_group_member('atendimento')`.
- Tres colunas protegidas em `grid_dev.bronze.chamados`: `nome_solicitante`, `telefone_solicitante` e `transcricao`.
- Funcao aplicada: `grid_dev.bronze.mascarar_dado_pessoal`. Retorna o original aos membros do grupo e `[RESTRITO]` aos demais.

[Job completo, incluindo governanca e metric view](https://dbc-1a1f7eb6-688b.cloud.databricks.com/jobs/607282318606996/runs/899827720377711) terminou em SUCCESS apos reparar a construcao das aspas no DDL da funcao. Pipeline: 393 segundos. Governanca corrigida: 6 segundos. Metric view: 3 segundos.

[Nova atualizacao com as mascaras ativas](https://dbc-1a1f7eb6-688b.cloud.databricks.com/#joblist/pipelines/9fa20cad-d7a6-4913-9b19-f735d828a0a8/updates/f985bb09-23fa-465a-aa5a-330065d61257) terminou em COMPLETED. As tres mascaras permaneceram aplicadas. A silver preservou 2.801 chamados e a assinatura `450080987629941661953`, igual a anterior.

A leitura com o membro autorizado preservou os 2.801 originais, sem valores substituidos por `[RESTRITO]`. Nao foi usada uma segunda identidade fora do grupo. O teste de leitura em `tests/aceite_governanca.sql` tambem cobre esse caso quando executado por uma identidade nao membro que tenha SELECT.
