#!/usr/bin/bash

## define variable
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=$BACKUP_PATH/bin
BACKUP_PATH_DATA=$BACKUP_PATH/data/restore
BACKUP_PATH_LOG=$BACKUP_PATH/log
RESTORE_LOG_FILE=$BACKUP_PATH_LOG/k8s-restore.log

## make dir
mkdir -p $BACKUP_PATH_BIN
mkdir -p $BACKUP_PATH_DATA
mkdir -p $BACKUP_PATH_LOG
cd $BACKUP_PATH_DATA

## print hint
message="`date` Kubernetes Restore start now. All yaml files which located in path ${BACKUP_PATH_DATA} will be applied." 
echo ${message} 2>&1 >> $RESTORE_LOG_FILE
echo ${message} 
echo "`date` If you want to read the record of restore, please input command ' tail -100f ${RESTORE_LOG_FILE} '"

## list yaml files 
file_list=`ls -n ${BACKUP_PATH_DATA}/*.yaml | awk '{print $9}'`
file_count=`echo ${file_list} | wc -w`

## ask and answer
message="WARNING!!! This will create ${file_count} yaml files to kubernetes cluster. While same name resources will be deleted. Please consider it carefully!"
echo ${message} 2>&1 >> $RESTORE_LOG_FILE
echo ${message} 
read -n 1 -p "Do you want to continue? [yes/no/show] " input_char && printf "\n"
if [ "${input_char}" == 's'  ]; then
   message="`date` Show yaml files list."
   echo $message 2>&1 >> $RESTORE_LOG_FILE
   echo $message
   ls -n ${BACKUP_PATH_DATA}/*.yaml
   exit 1
elif [ "${input_char}" != 'y'  ]; then
   message="`date` Exit by user's selection."
   echo $message 2>&1 >> $RESTORE_LOG_FILE
   echo $message
   exit 2
fi

## loop for file list
COUNT=0
for file_yaml in $file_list; do
    COUNT=`expr $COUNT + 1`
    echo "`date` Restore No.${COUNT} yaml file: ${file_yaml}..." 2>&1 >> $RESTORE_LOG_FILE
	cmd_delete="kubectl delete -f ${file_yaml}"
	cmd_create="kubectl create -f ${file_yaml}"
	
	## run delete
	echo "`date` Run shell: ${cmd_delete}." 2>&1 >> $RESTORE_LOG_FILE
	${cmd_delete}
	result="failed"
	if [ $? -eq 0 ]; then
        result="ok"
	fi
	echo "`date` Delete resource ${result}." 2>&1 >> $RESTORE_LOG_FILE
	
	## run create
	echo "`date` Run shell: ${cmd_create}." 2>&1 >> $RESTORE_LOG_FILE
	${cmd_create}
	result="failed"
	if [ $? -eq 0 ]; then
        result="ok"        
	fi
	echo "`date` Create resource ${result}." 2>&1 >> $RESTORE_LOG_FILE
done;

## show stats
message="`date` Restore ${COUNT} yaml files in all."
echo ${message}
echo ${message} 2>&1 >> $RESTORE_LOG_FILE
echo "`date` Kubernetes Restore completed, all done." 2>&1 >> $RESTORE_LOG_FILE
exit 0;
