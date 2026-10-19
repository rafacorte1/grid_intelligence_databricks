import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
from types import SimpleNamespace


PATH = Path(__file__).resolve().parents[1] / 'scripts/aplicar_genie.py'


class AplicarGenieTest(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'Script de aplicacao ainda nao implementado')
        spec = importlib.util.spec_from_file_location('aplicar_genie', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_render_preserva_template_e_texto(self):
        original = {'sql': ['SELECT * FROM ${catalogo}.gold.painel_operacional_dia'],
                    'texto': ['Pergunta com "aspas" e\nquebra']}
        rendered = self.module.render_space(original, 'catalogo-teste')
        self.assertEqual(rendered['sql'], ['SELECT * FROM catalogo-teste.gold.painel_operacional_dia'])
        self.assertEqual(rendered['texto'], original['texto'])
        self.assertIn('${catalogo}', original['sql'][0])

    def test_busca_recusa_titulos_ambiguos(self):
        spaces = [{'space_id': 'a', 'title': 'Copiloto'}, {'space_id': 'b', 'title': 'Copiloto'}]
        with self.assertRaisesRegex(ValueError, 'Mais de um'):
            self.module.find_space(spaces, 'Copiloto')

    def test_busca_reutiliza_space_existente(self):
        spaces = [{'space_id': 'a', 'title': 'Outro'}, {'space_id': 'b', 'title': 'Copiloto'}]
        self.assertEqual(self.module.find_space(spaces, 'Copiloto'), 'b')
        self.assertIsNone(self.module.find_space(spaces, 'Novo'))

    def test_opcoes_cli_nao_viram_sql(self):
        with patch.object(self.module.subprocess, 'run', return_value=SimpleNamespace(
                returncode=0, stdout='[]', stderr='')) as run:
            self.module.cli('perfil', 'experimental', 'aitools', 'tools', 'query', '--', 'SELECT 1')
        command = run.call_args.args[0]
        self.assertEqual(command[command.index('--') + 1:], ['SELECT 1'])

    def test_contexto_resolve_host_do_perfil_sem_host_publico(self):
        bundle = {'variables': {'catalog': {'value': 'demo'}, 'warehouse_id': {'value': 'wh'}},
                  'workspace': {}}
        with patch.object(self.module, 'cli', side_effect=[bundle, {
                'details': {'host': 'https://workspace.example/'}}]):
            self.assertEqual(self.module.context('perfil', 'dev'), {
                'catalog': 'demo', 'warehouse': 'wh', 'host': 'https://workspace.example'})


if __name__ == '__main__':
    unittest.main()
