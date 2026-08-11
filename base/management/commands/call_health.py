# -*- coding: utf-8 -*-
"""How are calls actually doing?

Written because answering that question meant grepping journalctl by hand
every time, which is slow, easy to get subtly wrong, and impossible for
anyone else to repeat. The numbers come from CALLTRACE lines the call code
already writes.

The number that matters is accept -> connect: of the calls somebody
answered, how many carried audio. "Accepted" only says a finger hit a
button; CALLTRACE media is written when media genuinely started flowing, so
the gap between them is the accept-that-never-connected case.

    manage.py call_health                # last 24 hours
    manage.py call_health --hours 168    # last week
"""
import re
import subprocess
from collections import Counter

from django.core.management.base import BaseCommand

RING = re.compile(r'CALLTRACE ring call=(\w+).*?-> (\S+).*?'
                  r'voip=(\d+)/(\d+) fcm=(\d+)/(\d+)')
STATUS = re.compile(r'CALLTRACE status call=(\w+).*?status=(\w+)')
MEDIA = re.compile(r'CALLTRACE media call=(\w+)')
GUARD = re.compile(r'CALLTRACE (revive|ignore|ignore-accept|reconnect|retire) ')


class Command(BaseCommand):
    help = 'Report call reliability from the CALLTRACE log.'

    def add_arguments(self, parser):
        parser.add_argument('--hours', type=int, default=24)
        parser.add_argument(
            '--unit', default='adsyclub',
            help='systemd unit carrying the log (default adsyclub).')

    def handle(self, *args, **options):
        hours = options['hours']
        try:
            log = subprocess.run(
                ['journalctl', '-u', options['unit'],
                 '--since', '%d hours ago' % hours, '--no-pager'],
                capture_output=True, text=True, timeout=180,
            ).stdout
        except Exception as exc:
            self.stderr.write('could not read the journal: %s' % exc)
            return

        rung, answered, connected = set(), set(), set()
        outcomes, guards, unreachable = Counter(), Counter(), 0
        no_voip = 0

        for line in log.splitlines():
            m = RING.search(line)
            if m:
                rung.add(m.group(1))
                if 'reachable=False' in line:
                    unreachable += 1
                if m.group(3) == '0':
                    no_voip += 1
            m = STATUS.search(line)
            if m:
                outcomes[m.group(2)] += 1
                if m.group(2) == 'accepted':
                    answered.add(m.group(1))
            m = MEDIA.search(line)
            if m:
                connected.add(m.group(1))
            m = GUARD.search(line)
            if m:
                guards[m.group(1)] += 1

        both = answered & connected
        self.stdout.write(self.style.MIGRATE_HEADING(
            'Calls over the last %d hour(s)' % hours))
        self.stdout.write('  rung ......................... %d' % len(rung))
        self.stdout.write('  answered ..................... %d' % len(answered))
        self.stdout.write('  reached media ................ %d' % len(connected))
        if answered:
            rate = len(both) * 100 // len(answered)
            line = '  accept -> connect ............ %d%%' % rate
            self.stdout.write(
                self.style.SUCCESS(line) if rate >= 95
                else self.style.WARNING(line))
        self.stdout.write('  rang nobody at all ........... %d' % unreachable)

        stranded = sorted(answered - connected)
        if stranded:
            self.stdout.write('')
            self.stdout.write(self.style.WARNING(
                'answered but never connected (%d):' % len(stranded)))
            for call in stranded[:15]:
                self.stdout.write('    call=%s' % call)

        self.stdout.write('')
        self.stdout.write('outcomes:')
        for name, n in outcomes.most_common():
            self.stdout.write('    %-16s %d' % (name, n))

        self.stdout.write('')
        self.stdout.write('guards fired:')
        if guards:
            for name, n in guards.most_common():
                self.stdout.write('    %-16s %d' % (name, n))
        else:
            self.stdout.write('    none — no call needed rescuing')
