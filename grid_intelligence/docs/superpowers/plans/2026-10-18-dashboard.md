# Dashboard AI/BI — plano

Especificacao: prompts/05-dashboard.md. Publicar somente dev, usando o perfil
grid_intelligence, o warehouse existente e a gold como contexto dos datasets.

- [x] Criar src/dashboards/grid_intelligence.lvdash.json com duas paginas:
  operacao, com quatro KPIs temporais, serie de chamados/horas-UC, DEC via
  MEASURE e acoes atuais; inspecao e clientes, com aviso de prioridade,
  distribuicao por bairro e tabelas de evidencia e ultima fala anonimizada.
- [x] Declarar resources/grid_intelligence.dashboard.yml com dataset_catalog,
  dataset_schema e warehouse_id referenciados do bundle.
- [x] Executar cada SQL via CLI no contexto gold e verificar bindings e versoes.
- [ ] Concluir aceite visual final. Deploy e publicacao em dev realizados; abrir ambas as paginas no navegador,
  conferir os widgets e filtros e salvar um print real da pagina 1.

Recorte temporal ancorado no dataset. Prioridade de inspecao e uma fotografia
da ultima carga: indicar a limitacao do historico no quarto KPI. Nao recalcular
DEC/FEC, nao acessar bronze/silver e nao ampliar permissoes de compartilhamento.

Deploy inicial concluido. Eixo duplo corrigido no editor e publicado, com a
configuracao equivalente preservada no JSON local. A reconciliacao final do
bundle exige autorizacao explicita para --force por causa do etag remoto.

A verificacao SQL passou, mas a sessao final apresentou DEC em branco de forma
intermitente. Print mantido privado; aceite visual final permanece pendente.
