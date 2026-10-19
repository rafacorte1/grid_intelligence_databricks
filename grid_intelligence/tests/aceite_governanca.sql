-- Run with the identity you want to verify. Does not print personal data.
SELECT assert_true(count(*) = 3 AND count(DISTINCT column_name) = 3,
  'Expected a mask on all three personal columns of Bronze')
FROM grid_dev.information_schema.column_masks
WHERE table_schema = 'bronze' AND table_name = 'chamados'
  AND column_name IN ('nome_solicitante', 'telefone_solicitante', 'transcricao')
  AND mask_name = 'grid_dev.bronze.mascarar_dado_pessoal';

SELECT assert_true(count(*) = 2801, 'Original service calls must be preserved'),
  assert_true(count_if(
    CASE WHEN is_account_group_member('atendimento') THEN
      nome_solicitante = '[RESTRITO]' OR telefone_solicitante = '[RESTRITO]'
      OR transcricao = '[RESTRITO]'
    ELSE nome_solicitante <> '[RESTRITO]' OR telefone_solicitante <> '[RESTRITO]'
      OR transcricao <> '[RESTRITO]' END) = 0,
    'The read result must respect membership in the service group')
FROM grid_dev.bronze.chamados;
