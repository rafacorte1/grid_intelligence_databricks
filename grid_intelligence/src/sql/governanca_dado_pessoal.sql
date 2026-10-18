USE CATALOG IDENTIFIER(:catalogo);
USE SCHEMA IDENTIFIER(:schema_bronze);

-- Sem acesso ao original, a proxima atualizacao materializaria o texto [RESTRITO].
SELECT assert_true(is_account_group_member(:grupo_atendimento),
  'A identidade do pipeline/job deve integrar o grupo de atendimento antes de aplicar mascaras');

-- Full refresh pode recriar a tabela e remover mascaras. Reaplicar depois do pipeline.
-- A identidade do pipeline precisa integrar o grupo para anonimizar o original
-- nas execucoes seguintes. Nao ha excecao por proprietario ou administrador.
-- Parametros nao sao capturados pelo corpo persistente de uma funcao SQL.
-- chr(39) preserva as aspas no SQL gerado, sem concatenacao de literais adjacentes.
EXECUTE IMMEDIATE
  'CREATE OR REPLACE FUNCTION mascarar_dado_pessoal(valor STRING) RETURN CASE WHEN '
  || 'is_account_group_member(' || chr(39)
  || replace(replace(:grupo_atendimento, chr(92), concat(chr(92), chr(92))),
       chr(39), concat(chr(92), chr(39)))
  || chr(39) || ') THEN valor ELSE ' || chr(39) || '[RESTRITO]' || chr(39) || ' END';

ALTER TABLE chamados ALTER COLUMN nome_solicitante SET MASK mascarar_dado_pessoal;
ALTER TABLE chamados ALTER COLUMN telefone_solicitante SET MASK mascarar_dado_pessoal;
ALTER TABLE chamados ALTER COLUMN transcricao SET MASK mascarar_dado_pessoal;
