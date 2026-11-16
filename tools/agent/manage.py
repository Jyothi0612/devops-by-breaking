#!/usr/bin/env python3
"""Trusted config/report conversion, executed in the pinned Python image."""
import json
import sys


def eligible(agent):
    return (agent.get('agent_exit_code') == 0 and not agent.get('timed_out')
            and not agent.get('budget_exceeded') and not agent.get('broker_error'))


def report(agent, lab, maximum, check_rc, rows):
    objectives = []
    for row in rows.splitlines():
        state, _, name = row.partition('\t')
        objectives.append({'name': name, 'passed': state == 'PASS'})
    checked = check_rc is not None
    check_passed = checked and check_rc == 0 and bool(objectives) and all(
        objective['passed'] for objective in objectives)
    return dict(agent, lab=lab, passed=eligible(agent) and check_passed,
                max_commands=maximum, check_exit_code=check_rc,
                check={'lab': lab, 'passed': check_passed, 'objectives': objectives} if checked else None)


def main():
    action = sys.argv[1]
    if action == 'config':
        lab, runtime, root, rpc, image, network, maximum, timeout, tf_image, ans_image = sys.argv[2:12]
        config = dict(lab=lab, runtime=runtime, workspace=root + '/workspace/' + lab,
                      inputs=sys.argv[12] + '/inputs', rpc=rpc, image=image, network=network,
                      max_commands=int(maximum), timeout=int(timeout),
                      terraform_image=tf_image, ansible_image=ans_image,
                      uid=sys.argv[13], gid=sys.argv[14], command=sys.argv[15:])
        with open('/run/config.json', 'w') as stream:
            json.dump(config, stream)
    elif action == 'eligible':
        with open('/run/agent.json') as stream:
            return 0 if eligible(json.load(stream)) else 1
    elif action == 'report':
        with open('/run/agent.json') as stream:
            agent = json.load(stream)
        rc = None if sys.argv[4] == 'skipped' else int(sys.argv[4])
        with open('/run/objectives.tsv') as stream:
            result = report(agent, sys.argv[2], int(sys.argv[3]), rc, stream.read())
        with open('/run/result.json', 'w') as stream:
            json.dump(result, stream, indent=2)
            stream.write('\n')
        return 0 if result['passed'] else 1
    else:
        raise ValueError('unknown action')
    return 0


if __name__ == '__main__':
    sys.exit(main())
