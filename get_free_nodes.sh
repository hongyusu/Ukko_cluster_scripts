



#!/bin/bash

function get_free_nodes()
{
	waitingtime=15
	required_num=150
	wired_nodes=('ukko001' 'ukko002' 'ukko003' 'ukko083')
	ukkoinfor='http://www.cs.helsinki.fi/u/jjaakkol/hpc-report.txt'
	ukkoinforfile='/fs/group/urenzyme/workspace/netscripts/ukkoinfor.txt'
	workingdir='/fs/group/urenzyme/workspace/netscripts/'
	tmpfile='/fs/group/urenzyme/workspace/netscripts/tmpfile'

	#echo 'Finding nice nodes ...'
	#echo "Read node list file from " $ukkoinfor
	wget $ukkoinfor -O $ukkoinforfile
        if [[ $(hostname) == ukko* ]] 
        then
                suffix=''
        else
                suffix='.hpc'
        fi
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
	for node in ${nodes[@]}
	do
                ssh -o StrictHostKeyChecking=no $node$suffix 'upt=$(uptime);memfree="$(cat /proc/meminfo | grep MemFree | cut -d: -f2 | cut -dk -f1)";memtotal="$(cat /proc/meminfo | grep MemTotal | cut -d: -f2 | cut -dk -f1)";percent=$(echo "scale=5; 100-$memfree/$memtotal*100" | bc -l);node=$(hostname);echo "${node}${upt} ${percent}"|sed -e "s/ .* load average://" -e "s/,//g" > /home/group/urenzyme/workspace/netscripts/$node' &
	done
	sleep $waitingtime
	pkill -u su -f "upt="
	for node in ${nodes[@]}
	do
		filename=$workingdir$node
		if [ -e $filename ]
		then
		        cat $filename >> ${workingdir}ukko
		fi
	done

	sort ${workingdir}ukko -k2 -n | sed 's/ .*//' > ${workingdir}ukkotmp
	mv ${workingdir}ukkotmp ${workingdir}ukko
	exec<${workingdir}ukko
	unset nodes
	nodesnum=0
	while read line
	do
		nodes[$nodesnum]=$line
		nodesnum=$(($nodesnum+1))
	done
	rm ${workingdir}ukko*
	
	if [ $nodesnum -le $required_num ]
	then
		exit
	fi
        
        for node in ${nodes[@]}
        do
                echo $node$suffix
        done
}

get_free_nodes





