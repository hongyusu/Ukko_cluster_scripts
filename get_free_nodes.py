

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
required_num = 120 
workingdir = '/cs/work/group/urenzyme/workspace/netscripts/'

def get_free_nodes():
	logging.info("\tObtaining nodes of good quality from UKKO cluster ...")
        nodes = []
        node2load = {}
        loads = []
        cluster = []
        # attemp connect and collect information
        starter = commands.getoutput('hostname')
        for i in range(0,241):
                if i==60:
                        continue
                if starter.startswith('ukko'):
                        nodes.append('ukko%03d' % i)
                else:
                        nodes.append('ukko%03d.hpc' % i)
        logging.info("\tCollecting information for %d s" % waitingtime)
        for node in nodes:
                os.system('''ssh -o BatchMode=yes -q -o StrictHostKeyChecking=no %s 'upt=$(uptime);memfree="$(cat /proc/meminfo | grep MemFree | cut -d: -f2 | cut -dk -f1)";memtotal="$(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | cut -dk -f1)";percent=$(echo "scale=5; $memfree/$memtotal*100" | bc -l);node=$(hostname);echo "${node}${upt} ${percent}"|sed -e "s/ .* load average://" -e "s/,//g"  > %s%s' &''' % (node,workingdir,node))
	time.sleep(waitingtime)
	os.system('pkill -u su -f "upt="')
        time.sleep(2)
	for node in nodes:
		infile = "%s%s" % (workingdir,node)
		if os.path.isfile("%s" % (infile)):
			fin = open("%s" % (infile))
			for line in fin:
                                words = line.strip().split(' ')
                                if starter.startswith('ukko'):
                                        node = words[0]
                                else:
                                        node = words[0]+'.hpc'
                                load = float(words[1])
				node2load[node] = load
				loads.append(load)
			fin.close()
		os.system("rm -f %s" % infile)
	logging.info("\tRequired node # : %d" % required_num)
	logging.info("\tGood node #     : %d" % len(loads))
	if required_num > len(loads):
		logging.warning("\t Error: not enough nodes")
		exit()
	logging.info("\tProcessing node information...")
        node2load_sorted=sorted([(value,key) for (key,value) in node2load.items()])
	loads.sort()
	threshold = loads[required_num-1]
	logging.info("\tLoad threshold: %.2f" % threshold)
	for nodetuple in node2load_sorted:
                cluster.append(nodetuple[1])
		if len(cluster) == required_num:
			break
	return [cluster, node2load.keys()]


if __name__ == '__main__':
	get_free_nodes()

