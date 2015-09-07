

#!/usr/bin/env python
#-*- coding: iso-8859-15 -*-

import sys
import os
import re
import urllib
import time
import commands
import logging

logging.basicConfig(format='%(asctime)s %(filename)s %(funcName)s %(levelname)s:%(message)s', level=logging.INFO)

waitingtime = 30
workingdir = '/cs/work/group/urenzyme/workspace/netscripts/'

def kill_processes():
        nodes = []
        print("Kill processes on ukko (waiting for %d sec)" % waitingtime)
        # attemp connect and collect information
        starter = commands.getoutput('hostname')
        for i in range(0,241):
                if starter.startswith('ukko'):
                        nodes.append('ukko%03d' % i)
                else:
                        nodes.append('ukko%03d.hpc' % i)
        for node in nodes:
                res = os.system('''ssh -o BatchMode=yes -q -o StrictHostKeyChecking=no %s 'rm /var/tmp/*; pkill -u su -f single_kernel' &''' % (node))
                time.sleep(0.1)
	time.sleep(waitingtime)
	os.system('pkill -u su -f "pkill"')
        pass

if __name__ == '__main__':
	kill_processes()

