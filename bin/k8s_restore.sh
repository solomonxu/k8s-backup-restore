#!/usr/bin/bash

## define constants
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=${BACKUP_PATH}/bin
BACKUP_PATH_DATA=${BACKUP_PATH}/data/restore

## define constants
LOG_PATH=${BACKUP_PATH}/logs
LOG_OUTPUT_FILE_DEFAULT="${LOG_PATH}/restore.log"

## Include shells
. ${BACKUP_PATH}/bin/logger.sh

## make dir
mkdir -p ${BACKUP_PATH_BIN}
mkdir -p ${BACKUP_PATH_DATA}
mkdir -p ${LOG_PATH}
cd ${BACKUP_PATH_DATA}

## print hint
logger_info "Kubernetes Restore start now. All yaml files which located in path [${BACKUP_PATH_DATA}] will be applied." 
logger_info "If you want to read the log record of restore, please input command ' tail -100f ${RESTORE_LOG_FILE} '"

## list yaml files 
_file_list=$(ls -n ${BACKUP_PATH_DATA}/*.yaml | awk '{print $9}')
_file_count=$(echo ${_file_list} | wc -w)

## ask and answer
logger_warn "WARNING!!! This will create ${_file_count} resources from yaml files into kubernetes cluster. While same name of resources will be deleted. Please consider it carefully!"
read -n 1 -p "Do you want to continue? [yes/no/show] " input_char && printf "\n"
if [ "${input_char}" == 's'  ]; then
    logger_info "Show yaml files list, then exit."
    ls -n ${BACKUP_PATH_DATA}/*.yaml
    exit 1
elif [ "${input_char}" != 'y'  ]; then
    logger_info "Exit by user's selection."
    exit 2
fi

## loop for file list
_count=0
_count_delete_ok=0
_count_create_ok=0
_count_delete_failed=0
_count_create_failed=0
for _file_yaml in ${_file_list}; do
    _count=$[_count + 1]
    logger_info "Restore No.${_count} resources from yaml file: ${_file_yaml}..."
    _cmd_delete="kubectl delete -f ${_file_yaml}"
    _cmd_create="kubectl create -f ${_file_yaml}"
	
    ## run delete
    logger_info "Run shell: ${_cmd_delete}."
    kubectl delete -f ${_file_yaml}
    if [ $? -eq 0 ]; then
        _result="ok"
        _count_delete_ok=$[_count_delete_ok+1]
    else
        _result="failed"
        _count_delete_failed=$[_count_delete_failed+1]
    fi
    logger_info "Delete resource from ${_file_yaml}: ${_result}."

    ## run create
    logger_info "Run shell: ${_cmd_create}."
    kubectl create -f ${_file_yaml}
    if [ $? -eq 0 ]; then
        _result="ok"
        _count_create_ok=$[_count_create_ok+1]
    else
        _result="failed"
        _count_create_failed=$[_count_create_failed+1]
    fi
    logger_info "Create resource from ${_file_yaml}: ${_result}."
done;

## show stats
logger_info "Restore ${_count} resources from yaml files in all: count_delete_ok=${_count_delete_ok}, count_delete_failed=${_count_delete_failed}, count_create_ok=${_count_create_ok}, count_create_failed=${_count_create_failed}."
logger_info "Kubernetes Restore completed, all done."
exit 0;
