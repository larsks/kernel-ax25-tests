#!/usr/bin/python3 -u

import sys

print('When you say ping, I say pong.')
for line in sys.stdin:
    cmd = line.strip()

    if cmd == 'ping':
        sys.stdout.write('pong\n')
    elif cmd == 'quit':
        break
