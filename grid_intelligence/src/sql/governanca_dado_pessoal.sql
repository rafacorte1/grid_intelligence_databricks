USE CATALOG IDENTIFIER(:catalogo);
USE SCHEMA IDENTIFIER(:schema_bronze);

-- Without access to the original, the next refresh would materialize the [RESTRITO] placeholder.
SELECT assert_true(is_account_group_member(:grupo_atendimento),
  'The pipeline/job identity must belong to the service group before masks are applied');

-- A full refresh can recreate the table and drop the masks. Reapply after the pipeline.
-- The pipeline identity must belong to the group to anonymize the original text in
-- later runs. There is no owner or administrator exception.
-- Parameters are not captured by the persistent body of a SQL function.
-- chr(39) preserves the quotes in the generated SQL without concatenating adjacent literals.
EXECUTE IMMEDIATE
  'CREATE OR REPLACE FUNCTION mascarar_dado_pessoal(valor STRING) RETURN CASE WHEN '
  || 'is_account_group_member(' || chr(39)
  || replace(replace(:grupo_atendimento, chr(92), concat(chr(92), chr(92))),
       chr(39), concat(chr(92), chr(39)))
  || chr(39) || ') THEN valor ELSE ' || chr(39) || '[RESTRITO]' || chr(39) || ' END';

ALTER TABLE chamados ALTER COLUMN nome_solicitante SET MASK mascarar_dado_pessoal;
ALTER TABLE chamados ALTER COLUMN telefone_solicitante SET MASK mascarar_dado_pessoal;
ALTER TABLE chamados ALTER COLUMN transcricao SET MASK mascarar_dado_pessoal;
