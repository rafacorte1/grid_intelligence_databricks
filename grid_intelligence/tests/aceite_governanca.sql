-- Executar com a identidade que se deseja verificar. Nao imprime dados pessoais.
SELECT assert_true(count(*) = 3 AND count(DISTINCT column_name) = 3,
  'Esperado mascara nas tres colunas pessoais da bronze')
FROM grid_dev.information_schema.column_masks
WHERE table_schema = 'bronze' AND table_name = 'chamados'
  AND column_name IN ('nome_solicitante', 'telefone_solicitante', 'transcricao')
  AND mask_name = 'grid_dev.bronze.mascarar_dado_pessoal';

SELECT assert_true(count(*) = 2801, 'Chamados originais devem ser preservados'),
  assert_true(count_if(
    CASE WHEN is_account_group_member('atendimento') THEN
      nome_solicitante = '[RESTRITO]' OR telefone_solicitante = '[RESTRITO]'
      OR transcricao = '[RESTRITO]'
    ELSE nome_solicitante <> '[RESTRITO]' OR telefone_solicitante <> '[RESTRITO]'
      OR transcricao <> '[RESTRITO]' END) = 0,
    'Resultado da leitura deve respeitar a associacao ao grupo de atendimento')
FROM grid_dev.bronze.chamados;
