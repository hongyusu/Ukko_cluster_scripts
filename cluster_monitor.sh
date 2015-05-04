



#!/bin/bash

function cluster_monitor()
{
	waitingtime=15
	wired_nodes=('ukko001' 'ukko002' 'ukko003' 'ukko083')
	ukkoinfor='http://www.cs.helsinki.fi/u/jjaakkol/hpc-report.txt'
	ukkoinforfile='/fs-0/group/urenzyme/workspace/netscripts/ukkoinfor.txt'
	workingdir='/fs-0/group/urenzyme/workspace/netscripts/'
	tmpfile='/fs-0/group/urenzyme/workspace/netscripts/tmpfile'

	#echo 'Finding nice nodes ...'
	#echo "Read node list file from " $ukkoinfor
	wget $ukkoinfor -O $ukkoinforfile
	cat $ukkoinforfile | sed '1,5d' | grep '^ukko' | sed '/Reserve/d'  | sed -e 's/ +//' -e 's/\.hpc\.cs\.helsinki\.fi//' | awk -F' ' '{print $1" "$3" "$4" "$6" "$7}'> $tmpfile
	mv $tmpfile $ukkoinforfile

	declare -a nodes
	nodesnum=0
	exec<$ukkoinforfile
	while read line
	do
		# arraylize each line
		i=0
		for word in $(echo $line | tr " " "\n")
		do
		        words[$i]=$word
		        i=$(($i+1))
		done
		# check if go wired
		go_wired=0
		for wired_node in ${wired_nodes[@]}
		do
		        if [ "$wired_node" == "${words[0]}" ]
		        then
		                go_wired=1
		                break
		        fi
		done
		if [ $go_wired -eq "1" ]
		then
		        continue
		fi
		#others
		if [ "${words[1]}" == "yes" -a "${words[2]}" == "yes" -a "${words[3]}" != '-' ] && [ "${words[4]}" == 'cs' -o "${words[4]}" == 'cs/t' ]
		then
		       nodes[$nodesnum]=${words[0]} 
		       nodesnum=$(($nodesnum+1))
		fi

	done

	#echo "Collecting information for "$waitingtime" second ..."
        mkdir monitor_cluster
	for node in ${nodes[@]}
	do
                #ssh -o StrictHostKeyChecking=no $node 'upt=$(uptime);memfree="$(cat /proc/meminfo | grep MemFree | cut -d: -f2 | cut -dk -f1)";memtotal="$(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | cut -dk -f1)";percent=$(echo "scale=2; 100-$memfree/$memtotal*100" | bc -l);node=$(hostname);echo "${node}${upt} ${percent}"|sed -e "s/ .* load average://" -e "s/,//g" > /home/group/urenzyme/workspace/netscripts/monitor_cluster/$node;top -b -n 1 | sed -n 8,13p | sed "/ root/d" >> /home/group/urenzyme/workspace/netscripts/monitor_cluster/$node;' &
                ssh -o StrictHostKeyChecking=no $node 'upt=$(uptime|sed -e "s/ .* load average://" -e "s/,//g");memfree="$(cat /proc/meminfo | grep MemFree | cut -d: -f2 | cut -dk -f1)";memtotal="$(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | cut -dk -f1)";percent=$(echo "scale=2; 100-$memfree/$memtotal*100" | bc -l);node=$(hostname);top -b -n 1 | sed -n 8,13p | sed "/ root/d" | sed -e"s/^ */${node}${upt} ${percent} /g" > /home/group/urenzyme/workspace/netscripts/monitor_cluster/$node;' &
                sleep 0.1
	done
	sleep $waitingtime
	pkill -u su -f "upt="
        for node in ${nodes[@]}
        do
                file='/home/group/urenzyme/workspace/netscripts/monitor_cluster/'$node
                if [ -e $file ];then
                        cat $file 
                else
                        echo $node" 1000 1000 1000 1000 100 NA 100 100 NA 1000 1000 NA 1000 1000 NA NA"
                fi
        done
        rm -rf monitor_cluster
}

while [ 1 ]
do
        echo "var data=[" > ~/public_html/clusterMonitorData.js
        cluster_monitor | awk -F' ' '{print "[\""$1"\", "$2", "$3", "$4", "$5", \""$7"\", "$14", "$15", \""$16"\", \""$17"\"],"}' >> ~/public_html/clusterMonitorData.js
        echo "];" >> ~/public_html/clusterMonitorData.js
        echo "update on $(date)"
        echo "var updateTime=[\""$(date)"\"];" >> ~/public_html/clusterMonitorData.js
        sleep 600s
done





