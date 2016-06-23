#!/bin/bash

DOCKER="sudo docker"
IMAGE=worked
DOCKERHOST=localhost:3000

function build {
		echo "Building Master Image"
		$DOCKER build . 2>&1 | tee build.log
		id=`grep 'Successfully built' build.log  | cut -d" " -f 3`
		if [ "X${id}" == "X" ]
		then
			echo "build failed"
			exit 1
		fi

		$DOCKER tag -f ${id}  $IMAGE
}


function runem {
		for instance in `seq 1 $1`
		do
			# might give an error
			$DOCKER rm worked-instance${instance} >& /dev/null
	
			hash=`$DOCKER run -d \
				-p $((80+${instance})):80 \
				-h worked-instance${instance} --name=worked-instance${instance} \
				$IMAGE`
		done

		echo "======================= Docker Images ======================"
		$DOCKER ps
}


function killem {
	INSTANCES=`$DOCKER ps | grep worked-instance | awk '{print $11}'`
	for instance in $INSTANCES
	do
			$DOCKER kill ${instance} && $DOCKER rm ${instance}
	done
}

function checkem {
	INSTANCES=`$DOCKER ps| grep worked-instance | wc -l`
	if [ $INSTANCES -le 0 ]
	then
		echo "[ERROR] No Instances found "
		exit 1
	fi
	> usage.txt
	> processes.txt
	for instance in `seq 1 $INSTANCES`
	do
		curl -s http://localhost:$((80+${instance}))| grep worked-instance${instance} >& /dev/null
		if [ $? -ne 0 ]
		then
			echo "Instance ${instance} is not healthy"
		else
			echo "Instance  ${instance} is fine"
		fi

		echo worked-instance${instance} >> processes.txt
		$DOCKER exec worked-instance${instance} ps aux >> processes.txt	2>&1

		echo worked-instance${instance} >> usage.txt
		$DOCKER exec worked-instance${instance} w >> usage.txt	2>&1
	done

	echo Process list is in processes.txt , mem/cpu usage in usage.txt
}



function remote {
# current docker will not accept stream=false
 curl -s http://localhost:2376/containers/worked-instance${1}/stats?stream=false   | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '{print $1 " " $2}' | sed -e 's/\"//g'
}

function usage {
	echo "
Usage:
   [build image]                       ./$0 -b
   [run image instances]               ./$0 -r <num_instances>
   [delete image]                      ./$0 -d
   [kill running instances]            ./$0 -k
   [check instances]                   ./$0 -c
   [check instance via remote api]     ./$0 -a <instance_number>
"
}


while getopts ":r:a:cbk" opt; do
  echo "$opt was triggered, Parameter: $OPTARG" >&2
  case $opt in
    a)
		remote $OPTARG
	;;
    d)
		docker rmi -f $IMAGE
	;;
    k)
		echo "Killing Instances"
		killem
	;;
    r)
		runem $OPTARG
      ;;
    b)
	  build
      ;;
    c)
		checkem
      ;;
     \?)
		usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done



