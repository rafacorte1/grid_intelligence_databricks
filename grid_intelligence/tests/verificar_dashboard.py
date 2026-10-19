"""Valida os contratos do Lakeview e executa datasets e projecoes no warehouse."""

import argparse
import json
import re
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', required=True)
    parser.add_argument('--catalog', required=True)
    parser.add_argument('--schema', required=True)
    parser.add_argument('--warehouse', required=True)
    parser.add_argument('--results', type=Path)
    args = parser.parse_args()
    dashboard_path = Path(__file__).resolve().parents[1] / 'src/dashboards/grid_intelligence.lvdash.json'
    dashboard = json.loads(dashboard_path.read_text())
    datasets = {d['name']: ''.join(d['queryLines']) for d in dashboard['datasets']}
    versions = {'counter': 2, 'table': 2, 'bar': 3, 'line': 3, 'combo': 1,
                'filter-multi-select': 2, 'filter-date-range-picker': 2}
    assert len(dashboard['pages']) == 2
    assert dashboard['uiSettings']['theme']['visualizationColors']
    assert all('catalog' not in d and 'schema' not in d for d in dashboard['datasets'])
    checks = list(datasets.items())

    def bindings(value):
        if isinstance(value, dict):
            if 'fieldName' in value:
                yield value['fieldName']
            for child in value.values():
                yield from bindings(child)
        elif isinstance(value, list):
            for child in value:
                yield from bindings(child)

    for sql in datasets.values():
        assert not re.search(r'\b(?:FROM|JOIN)\s+\w+\.', sql, re.I), 'Usar tabelas sem namespace'
        assert 'grid_dev' not in sql and 'grid_intelligence.' not in sql
    assert 'MEASURE(`DEC`)' in datasets['continuidade']
    for page in dashboard['pages']:
        assert page['layoutVersion'] == 'GRID_V1' and 'widgets' not in page
        rectangles = []
        for item in page['layout']:
            p = item['position']
            assert 0 <= p['x'] < 12 and p['x'] + p['width'] <= 12
            for r in rectangles:
                assert not (p['x'] < r['x'] + r['width'] and r['x'] < p['x'] + p['width']
                            and p['y'] < r['y'] + r['height'] and r['y'] < p['y'] + p['height'])
            rectangles.append(p)
            w = item['widget']
            assert re.fullmatch(r'[A-Za-z0-9_-]{1,60}', w['name'])
            if 'spec' not in w:
                continue
            spec = w['spec']
            assert spec['version'] == versions[spec['widgetType']]
            names = {f['name'] for q in w['queries'] for f in q['query']['fields']}
            assert set(bindings(spec['encodings'])) <= names, w['name']
            if spec['widgetType'] == 'counter':
                assert 'period' in spec['encodings'] and p['height'] >= 3
            if spec['widgetType'] == 'combo':
                axes = spec['encodings']['y']
                assert 'scale' not in axes, 'Escala unica esconde o volume de chamados'
                assert all(axes[a]['scale']['type'] == 'quantitative'
                           for a in ('primary', 'secondary'))
            if w['name'] == 'periodo-serie':
                assert {q['query']['datasetName'] for q in w['queries']} == {'operacao'}
            for q in w['queries']:
                query = q['query']
                sql = datasets[query['datasetName']]
                columns = ', '.join(f"{f['expression']} AS `{f['name']}`" for f in query['fields'])
                projection = f'WITH dados AS ({sql}) SELECT {columns} FROM dados'
                if not query['disaggregated']:
                    projection += ' GROUP BY ALL'
                checks.append((f"{w['name']}/{q['name']}", projection))

    catalog = args.catalog.replace('`', '``')
    schema = args.schema.replace('`', '``')
    statements = [f'BEGIN USE CATALOG `{catalog}`; USE SCHEMA `{schema}`; {sql}; END'
                  for _, sql in checks]
    result = subprocess.run(
        ['databricks', 'experimental', 'aitools', 'tools', 'query', '--profile', args.profile,
         '--warehouse', args.warehouse, '--output', 'json', '--', *statements],
        capture_output=True, text=True,
    )
    if not result.stdout:
        raise RuntimeError(result.stderr)
    responses = json.loads(result.stdout)
    assert len(responses) == len(checks)
    if args.results:
        args.results.write_text(json.dumps(responses, ensure_ascii=False, indent=2))
    failed = []
    for (name, _), response in zip(checks, responses):
        print(f"{name}: {response['state']} ({len(response.get('rows', []))} linhas)")
        if response['state'] != 'SUCCEEDED':
            failed.append((name, response.get('error')))
    if failed:
        raise RuntimeError(json.dumps(failed, ensure_ascii=False))
    print(f'{len(checks)} consultas e contratos de widgets validados.')


if __name__ == '__main__':
    main()
