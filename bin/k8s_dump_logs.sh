#!/usr/bin/bash

## show usage
echo "usage: $0 [namespace]"
echo "	namespace: the default value is wisecloud-controller."

## define variable
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=${BACKUP_PATH}/bin
BACKUP_PATH_LOGFILE=${BACKUP_PATH}/data/logfile
SUB_PATH=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH_DATA=${BACKUP_PATH_LOGFILE}/${SUB_PATH}

## define variable
LOG_PATH=${BACKUP_PATH}/logs
LOG_OUTPUT_FILE_DEFAULT="${LOG_PATH}/backup.log"

## Include shells
. ${BACKUP_PATH}/bin/logger.sh

## make dir
mkdir -p ${BACKUP_PATH_BIN}
mkdir -p ${BACKUP_PATH_DATA}
mkdir -p ${LOG_PATH}
cd ${BACKUP_PATH_DATA}

## set namespace
_ns="wisecloud-controller"
if [ $# -ge 1 ]; then
	_ns="$1"
fi

## get pod in namespace
_pod_list=$(kubectl -n ${_ns} get pod | grep -v "NAME" | awk '{print $1}' | sort)

## define counters
_count=0
## loop for pod list
for _pod in ${_pod_list}; do
    _containers_list=$(kubectl -n ${_ns} describe pod ${_pod} | grep -v "    " | awk -F: '{if($1=="Containers"){found="true"} else if(found=="true" && substr($0,0,1)!=" "){exit(0)} else if(found=="true"){print $1}}')
	echo _containers_list=${_containers_list}
    for _container in ${_containers_list}; do
        _logfile=${BACKUP_PATH_DATA}/${_pod}.log
        if [ -n ${_container} ]; then
        	_container_arg="-c ${_container}"
        	_logfile=${BACKUP_PATH_DATA}/${_pod}_${_container}.log
        fi
        logger_info "Dump pod ${_pod} container ${_container} log to file: ${_logfile}."
        kubectl -n ${_ns} logs ${_pod} ${_container_arg} > ${_logfile} 
        logger_info "Dump pod ${_pod} log file done."
        _count=$[_count+1]
    done;
done;
logger_info "Dump ${_count} log files in [namespace: ${_ns}] done."

## package log files to a zip file
ZIP_FILE=${BACKUP_PATH_LOGFILE}/log_${_ns}_${SUB_PATH}.tar
logger_info "Package log files into zip file..."
cd ${BACKUP_PATH_LOGFILE}
tar -cvPf ${ZIP_FILE} ${SUB_PATH}
gzip ${ZIP_FILE}
logger_info "Package log files into zip file: ${ZIP_FILE}.gz done."
