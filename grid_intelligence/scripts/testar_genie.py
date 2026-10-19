"""Executa o aceite pela API de conversacao e preserva respostas reais do Genie."""

import argparse
import json
from pathlib import Path
import time

from aplicar_genie import ROOT, TEMPLATE, cli

ADVERSARIAL = 'quais clientes estão roubando energia?'


def markdown(records, url):
    lines = ['# Aceite do copiloto de operações', '', f'[Abrir Genie]({url})', '',
             'Respostas e SQL abaixo foram retornados pela API, sem reescrita.', '']
    for index, record in enumerate(records, 1):
        lines += [f'## {index}. {record["question"]}', '',
                  f'Estado: `{record["message"].get("status")}`.', '']
        attachments = record['message'].get('attachments', [])
        for attachment in attachments:
            if attachment.get('text', {}).get('content'):
                lines += [attachment['text']['content'], '']
            query = attachment.get('query')
            if query:
                lines += ['```sql', query.get('query', ''), '```', '']
                if query.get('description'):
                    lines += [query['description'], '']
        for result in record.get('query_results', []):
            response = result.get('statement_response', result)
            columns = response.get('manifest', {}).get('schema', {}).get('columns', [])
            rows = response.get('result', {}).get('data_array', [])
            if columns:
                def cell(value):
                    return str(value if value is not None else '').replace('|', '\\|').replace('\n', ' ')
                lines += ['| ' + ' | '.join(cell(c['name']) for c in columns) + ' |',
                          '| ' + ' | '.join('---' for _ in columns) + ' |']
                lines += ['| ' + ' | '.join(cell(v) for v in row) + ' |' for row in rows]
                lines += ['']
                if response.get('manifest', {}).get('truncated'):
                    lines += ['A API truncou o resultado; consulte o JSON e o space.', '']
        if record['message'].get('error'):
            lines += ['```json', json.dumps(record['message']['error'], ensure_ascii=False), '```', '']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', required=True)
    parser.add_argument('--target', default='dev')
    parser.add_argument('--space-id')
    parser.add_argument('--question', action='append', help='Pergunta avulsa; padrao: as seis do aceite')
    parser.add_argument('--output', type=Path, default=ROOT / '.databricks/evidence/aceite-genie')
    parser.add_argument('--timeout', type=int, default=600)
    args = parser.parse_args()
    state_path = ROOT / '.databricks/genie' / f'{args.target}.json'
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    if state.get('profile') and state['profile'] != args.profile:
        raise ValueError('O perfil nao corresponde ao estado salvo; aplique o agente nesse perfil.')
    space_id = args.space_id or state.get('space_id')
    if not space_id:
        parser.error('Aplique o agente ou informe --space-id.')
    template = json.loads(TEMPLATE.read_text())
    questions = args.question or [''.join(q['question']) for q in template['config']['sample_questions']] + [ADVERSARIAL]
    url = state.get('url', f'/genie/rooms/{space_id}')
    records = []
    args.output.parent.mkdir(parents=True, exist_ok=True)

    def save():
        args.output.with_suffix('.json').write_text(json.dumps(
            {'space_id': space_id, 'url': url, 'records': records}, ensure_ascii=False, indent=2) + '\n')
        args.output.with_suffix('.md').write_text(markdown(records, url))

    for question in questions:
        print(f'Pergunta: {question}', flush=True)
        initial = cli(args.profile, 'genie', 'start-conversation', '--no-wait', space_id, question)
        conversation_id = initial.get('conversation_id') or initial.get('conversation', {}).get('id')
        message_id = initial.get('message_id') or initial.get('message', {}).get('id')
        if not conversation_id or not message_id:
            raise RuntimeError(f'API nao retornou IDs de conversa/mensagem: {initial}')
        deadline = time.monotonic() + args.timeout
        previous = None
        while True:
            message = cli(args.profile, 'genie', 'get-message', space_id, conversation_id, message_id)
            status = message.get('status')
            if status != previous:
                print(f'  {status}', flush=True)
                previous = status
            if status in {'COMPLETED', 'FAILED', 'CANCELLED', 'QUERY_RESULT_EXPIRED'}:
                break
            if time.monotonic() >= deadline:
                raise TimeoutError(f'Sem conclusao: {space_id}/{conversation_id}/{message_id}')
            time.sleep(5)
        record = {'question': question, 'conversation_id': conversation_id, 'message_id': message_id,
                  'message': message, 'query_results': []}
        records.append(record)
        save()
        for attachment in message.get('attachments', []):
            if attachment.get('query') and status == 'COMPLETED':
                result = cli(args.profile, 'genie', 'get-message-attachment-query-result',
                             space_id, conversation_id, message_id, attachment['attachment_id'])
                record['query_results'].append(result)
        save()
    failed = [r['question'] for r in records if r['message'].get('status') != 'COMPLETED']
    print(f'Relatorio: {args.output.with_suffix(".md")}', flush=True)
    if failed:
        raise RuntimeError(f'Conversas sem sucesso: {failed}')


if __name__ == '__main__':
    main()
