#!/usr/bin/bash

## show usage
echo "usage: $0 [namespace]"

## define variable
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=${BACKUP_PATH}/bin
BACKUP_PATH_DATA=${BACKUP_PATH}/data/backup/$(date +%Y%m%d_%H%M%S)

## define variable
LOG_PATH=${BACKUP_PATH}/logs
LOG_OUTPUT_FILE_DEFAULT="${LOG_PATH}/backup.log"

## Include shells
. ${BACKUP_PATH}/bin/logger.sh

## set K8s type
_config_type_list=$(kubectl api-resources | grep -v "events" | awk '{print $1}' | sort)

## make dir
mkdir -p ${BACKUP_PATH_BIN}
mkdir -p ${BACKUP_PATH_DATA}
mkdir -p ${LOG_PATH}
cd ${BACKUP_PATH_DATA}

## set namespace list
_ns_list=$(kubectl get ns | awk '{print $1}' | grep -v NAME)
if [ $# -ge 1 ]; then
	_ns_list="$@"
fi

## define counters
_count0=0
_count1=0
_count2=0
_count3=0

## print hint
logger_info "Backup kubernetes config in [namespaces: ${_ns_list}] now."
logger_info "Backup kubernetes config for [type: ${_config_type_list}]."
logger_info "If you want to read the record of backup, please input command ' tail -100f ${LOG_OUTPUT_FILE_DEFAULT} '"

## ask and answer
logger_info "This will backup resources of kubernetes cluster to yaml files."
read -n 1 -p "Do you want to continue? [yes/no] " input_char && printf "\n"
if [ "${input_char}" != 'y'  ]; then
   logger_info "Exit by user's selection."
   exit 1
fi

## loop for namespaces
for _ns in ${_ns_list}; do
    _count0=$[_count0 + 1]
    logger_info "Backup No.${_count0} namespace [namespace: ${_ns}]."
	_count2=0
    ## loop for types
    for _type in ${_config_type_list}; do
	    logger_info "Backup type [namespace: ${_ns}, type: ${_type}]."
        _item_list=$(kubectl -n ${_ns} get ${_type} | grep -v NAME | awk '{print $1}' )
        _count1=0
	    ## loop for items
    	for _item in ${_item_list}; do
	        _file_name=${BACKUP_PATH_DATA}/${_ns}_${_type}_${_item}.yaml
		    logger_info "Backup kubernetes config yaml [namespace: ${_ns}, type: ${_type}, item: ${_item}] to file: ${_file_name}"
		    kubectl -n ${_ns} get ${_type} ${_item} -o yaml > ${_file_name}
		    _count1=$[_count1 + 1]
		    _count2=$[_count2 + 1]
		    _count3=$[_count3 + 1]
		    logger_info "Backup No.${_count3} file done."
        done;
    done;
    logger_info "Backup ${_count2} files done in [namespace: ${_ns}]."
done;

## show stats
logger_info "Backup ${_count3} yaml files in all."
logger_info "kubernetes Backup completed, all done."
exit 0
