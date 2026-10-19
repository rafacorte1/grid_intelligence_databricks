"""Aplica o Genie versionado usando o contexto do bundle e autenticacao da CLI."""

import argparse
import copy
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / 'src/genie/copiloto_operacoes.json'


def cli(profile, *arguments, payload=None):
    command = ['databricks', '--profile', profile, '--output', 'json', *arguments]
    with tempfile.TemporaryDirectory(prefix='grid-genie-') as directory:
        if payload is not None:
            request = Path(directory) / 'request.json'
            request.write_text(json.dumps(payload, ensure_ascii=False))
            command += ['--json', '@' + str(request)]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=300)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return json.loads(result.stdout) if result.stdout.strip() else {}


def render_space(template, catalog):
    def replace(value):
        if isinstance(value, str):
            return value.replace('${catalogo}', catalog)
        if isinstance(value, list):
            return [replace(item) for item in value]
        if isinstance(value, dict):
            return {key: replace(item) for key, item in value.items()}
        return value
    return replace(copy.deepcopy(template))


def find_space(spaces, title):
    matches = [s['space_id'] for s in spaces if s.get('title') == title]
    if len(matches) > 1:
        raise ValueError('Mais de um space com o mesmo titulo; informe --space-id.')
    return matches[0] if matches else None


def context(profile, target):
    bundle = cli(profile, 'bundle', 'summary', '-t', target)
    host = bundle['workspace'].get('host')
    if not host:
        host = cli(profile, 'auth', 'describe')['details']['host']
    return {
        'catalog': bundle['variables']['catalog']['value'],
        'warehouse': str(bundle['variables']['warehouse_id']['value']),
        'host': host.rstrip('/'),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', required=True)
    parser.add_argument('--target', default='dev')
    parser.add_argument('--space-id')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    ctx = context(args.profile, args.target)
    space = render_space(json.loads(TEMPLATE.read_text()), ctx['catalog'])
    # Exemplos ensinam o modelo: executar antes de tornar a definicao disponivel.
    examples = space['instructions']['example_question_sqls']
    sqls = [''.join(example['sql']) for example in examples]
    results = cli(args.profile, 'experimental', 'aitools', 'tools', 'query',
                  '--warehouse', ctx['warehouse'], '--', *sqls)
    for i, result in enumerate(results, 1):
        if result['state'] != 'SUCCEEDED':
            raise RuntimeError(f'Exemplo {i}: {result.get("error")}')
        print(f'Exemplo {i}: SQL aprovado ({len(result.get("rows", []))} linhas)', flush=True)
    if len(results) != len(examples):
        raise RuntimeError('A CLI nao retornou todos os exemplos.')
    title = f'[{args.target}] Grid Intelligence — Copiloto de operacoes'
    payload = {
        'title': title,
        'description': 'Copiloto em português para a diretoria da Luz do Vale: continuidade, '
                       'atendimento e prioridade de inspeção. Quatro fontes gold; sem acusações.',
        'warehouse_id': ctx['warehouse'],
        'serialized_space': json.dumps(space, ensure_ascii=False),
    }
    if args.dry_run:
        print('Dry-run: nenhuma criacao ou atualizacao realizada.')
        return
    space_id = args.space_id
    if not space_id:
        spaces, token = [], None
        while True:
            page_args = ['--page-token', token] if token else []
            page = cli(args.profile, 'genie', 'list-spaces', *page_args)
            spaces.extend(page.get('spaces', []))
            token = page.get('next_page_token')
            if not token:
                break
        space_id = find_space(spaces, title)
    if space_id:
        current = cli(args.profile, 'genie', 'get-space', space_id)
        if current.get('etag'):
            payload['etag'] = current['etag']
        applied = cli(args.profile, 'genie', 'update-space', space_id, payload=payload)
    else:
        applied = cli(args.profile, 'genie', 'create-space', payload=payload)
    space_id = applied.get('space_id', space_id)
    if not space_id:
        raise RuntimeError('API nao retornou o identificador do space.')
    state = {**ctx, 'space_id': space_id, 'target': args.target, 'profile': args.profile,
             'url': f'{ctx["host"]}/genie/rooms/{space_id}'}
    path = ROOT / '.databricks/genie' / f'{args.target}.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(state, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
