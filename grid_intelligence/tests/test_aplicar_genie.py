import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
from types import SimpleNamespace


PATH = Path(__file__).resolve().parents[1] / 'scripts/aplicar_genie.py'


class ApplyGenieTest(unittest.TestCase):
    def setUp(self):
        self.assertTrue(PATH.exists(), 'Application script is not implemented yet')
        spec = importlib.util.spec_from_file_location('aplicar_genie', PATH)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def test_render_preserves_template_and_text(self):
        original = {'sql': ['SELECT * FROM ${catalogo}.gold.painel_operacional_dia'],
                    'texto': ['Question with "quotes" and\na line break']}
        rendered = self.module.render_space(original, 'catalogo-teste')
        self.assertEqual(rendered['sql'], ['SELECT * FROM catalogo-teste.gold.painel_operacional_dia'])
        self.assertEqual(rendered['texto'], original['texto'])
        self.assertIn('${catalogo}', original['sql'][0])

    def test_lookup_rejects_ambiguous_titles(self):
        spaces = [{'space_id': 'a', 'title': 'Copiloto'}, {'space_id': 'b', 'title': 'Copiloto'}]
        with self.assertRaisesRegex(ValueError, 'More than one'):
            self.module.find_space(spaces, 'Copiloto')

    def test_lookup_reuses_existing_space(self):
        spaces = [{'space_id': 'a', 'title': 'Outro'}, {'space_id': 'b', 'title': 'Copiloto'}]
        self.assertEqual(self.module.find_space(spaces, 'Copiloto'), 'b')
        self.assertIsNone(self.module.find_space(spaces, 'Novo'))

    def test_cli_options_do_not_become_sql(self):
        with patch.object(self.module.subprocess, 'run', return_value=SimpleNamespace(
                returncode=0, stdout='[]', stderr='')) as run:
            self.module.cli('perfil', 'experimental', 'aitools', 'tools', 'query', '--', 'SELECT 1')
        command = run.call_args.args[0]
        self.assertEqual(command[command.index('--') + 1:], ['SELECT 1'])

    def test_context_resolves_profile_host_without_public_host(self):
        bundle = {'variables': {'catalog': {'value': 'demo'}, 'warehouse_id': {'value': 'wh'}},
                  'workspace': {}}
        with patch.object(self.module, 'cli', side_effect=[bundle, {
                'details': {'host': 'https://workspace.example/'}}]):
            self.assertEqual(self.module.context('perfil', 'dev'), {
                'catalog': 'demo', 'warehouse': 'wh', 'host': 'https://workspace.example'})


if __name__ == '__main__':
    unittest.main()
