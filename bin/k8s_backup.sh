#!/usr/bin/bash

## show usage
echo "usage: $0 [namespace]"

## define variable
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=$BACKUP_PATH/bin
BACKUP_PATH_DATA=$BACKUP_PATH/data/backup/`date +%Y%m%d%H%M%S`
BACKUP_PATH_LOG=$BACKUP_PATH/log
BACKUP_LOG_FILE=$BACKUP_PATH_LOG/k8s-backup.log

## set K8s type
CONFIG_TYPE="service deploy configmap secret job cronjob replicaset daemonset statefulset"

## make dir
mkdir -p $BACKUP_PATH_BIN
mkdir -p $BACKUP_PATH_DATA
mkdir -p $BACKUP_PATH_LOG
cd $BACKUP_PATH_DATA

## set namespace list
ns_list=`kubectl get ns | awk '{print $1}' | grep -v NAME`
if [ $# -ge 1 ]; then
	ns_list="$@"
fi

## define counters
COUNT0=0
COUNT1=0
COUNT2=0
COUNT3=0

## print hint
echo "`date` Backup kubernetes config in [namespaces: ${ns_list}] now."
echo "`date` Backup kubernetes config for [type: ${CONFIG_TYPE}]."
echo "`date` If you want to read the record of backup, please input command ' tail -100f ${BACKUP_LOG_FILE} '"

## ask and answer
message="This will backup resources of kubernetes cluster to yaml files."
echo ${message} 2>&1 >> $BACKUP_LOG_FILE
echo ${message} 
read -n 1 -p "Do you want to continue? [yes/no] " input_char && printf "\n"
if [ "${input_char}" != 'y'  ]; then
   message="`date` Exit by user's selection."
   echo $message 2>&1 >> $BACKUP_LOG_FILE
   echo $message
   exit 1
fi

## loop for namespaces
for ns in $ns_list; do
    COUNT0=`expr $COUNT0 + 1`
    echo "`date` Backup No.${COUNT0} namespace [namespace: ${ns}]." 2>&1 >> $BACKUP_LOG_FILE
	COUNT2=0
    ## loop for types
    for type in $CONFIG_TYPE; do
	    echo "`date` Backup type [namespace: ${ns}, type: ${type}]." 2>&1 >> $BACKUP_LOG_FILE
        item_list=`kubectl -n $ns get $type | awk '{print $1}' | grep -v NAME  | grep -v "No "`
        COUNT1=0
	    ## loop for items
    	for item in $item_list; do
	        file_name=$BACKUP_PATH_DATA/${ns}_${type}_${item}.yaml
		    echo "`date` Backup kubernetes config yaml [namespace: ${ns}, type: ${type}, item: ${item}] to file: ${file_name}" 2>&1 >> $BACKUP_LOG_FILE
		    kubectl -n $ns get $type $item -o yaml > $file_name
			COUNT1=`expr $COUNT1 + 1`
		    COUNT2=`expr $COUNT2 + 1`
			COUNT3=`expr $COUNT3 + 1`
		    echo "`date` Backup No.$COUNT3 file done."  2>&1 >> $BACKUP_LOG_FILE
        done;
    done;
	echo "`date` Backup ${COUNT2} files done in [namespace: ${ns}]." 2>&1 >> $BACKUP_LOG_FILE
done;

## show stats
message="`date` Backup ${COUNT3} yaml files in all."
echo ${message}
echo ${message} 2>&1 >> $BACKUP_LOG_FILE
echo "`date` kubernetes Backup completed, all done." 2>&1 >> $BACKUP_LOG_FILE
exit 0
