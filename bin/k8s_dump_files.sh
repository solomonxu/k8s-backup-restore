#!/usr/bin/bash

## show usage
echo "usage: $0 [configfile]"
echo "	configfile: the default config file is podfile.conf"

## define variable
BACKUP_PATH=/data/k8s-backup-restore
BACKUP_PATH_BIN=${BACKUP_PATH}/bin
BACKUP_PATH_PODFILE=${BACKUP_PATH}/data/podfile
SUB_PATH=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH_DATA=${BACKUP_PATH_PODFILE}/${SUB_PATH}

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

## set config file
_config_file=${BACKUP_PATH}/conf/podfile.conf
if [ $# -ge 1 ]; then
	_config_file=${BACKUP_PATH}/conf/$1
fi

## define counters
_count=0
## Dump container's files 
function dump_container_files()
{
    ## check pod config file
    if [ ! -f "${_config_file}" ]; then
        logger_error "Pod config ${_config_file} not existed, exit."
        exit 1;
    fi
    ## read pod config file
    _podfile_list=$(cat ${_config_file} | grep -v "##" | awk 'BEGIN{OFS="#"}{if($0!=""){print $1,$2,$3,$4}}')
	logger_info "_podfile_list=${_podfile_list}"
	_namespace_prior=""
    ## loop for podfile list
    for _podfile_line in ${_podfile_list}; do
        ## check podfile line
        if [ -z "${_podfile_line}" ]; then
            continue;
        fi
        logger_info "_podfile_line="${_podfile_line}
        _namespace=$( echo ${_podfile_line} | awk -F# '{print $1}')
        _pod_prefix=$(echo ${_podfile_line} | awk -F# '{print $2}')
        _container=$( echo ${_podfile_line} | awk -F# '{print $3}')
        _file_item=$( echo ${_podfile_line} | awk -F# '{print $4}')
        _file_list=$( echo ${_file_item} | awk -F: '{print $1}')
        logger_info "_namespace=${_namespace}, _pod_prefix=${_pod_prefix}, _container=${_container}, _file_list=${_file_list}"
        ## check pod argument
        if [ -z "${_pod_prefix}" ]; then
            continue;
        fi
        ## set to prior namespace
        if [ -z "${_namespace}" ]; then
            _namespace=${_namespace_prior}
        fi
        _namespace_prior=${_namespace}
        ## set namespace argument
        _ns_arg="--all-namespaces"
        if [ -n "${_namespace}" ]; then
            _ns_arg="-n ${_namespace}"
        fi
        ## set container argument
        _container_arg=""
        _container_suffix="default"
        if [ "${_container}" != "-" ]; then
            _container_arg="-c ${_container}"
			_container_suffix=${_container}
        fi
        ## get pod list
        _pod_list=$(kubectl get pods ${_ns_arg} | grep -v "NAME" | grep "${_pod_prefix}-" | awk '{print $1}')
        for _pod in ${_pod_list}; do
            _pod_root=${BACKUP_PATH_DATA}/"${_namespace}_pod_${_pod}_${_container_suffix}"
            mkdir -p ${_pod_root}
            ## loop for file list
            for _file in ${_file_list}; do
                _local_file="${_pod_root}${_file}"
                _local_dir="${_pod_root}${_file%/*}"
                mkdir -p ${_local_dir}
                ## dump file/dir from container to local host
                logger_info "Dump pod ${_pod} container ${_container} file ${_file} to local host: ${_local_file}."
                _ret_val=$(kubectl ${_ns_arg} cp ${_pod}:${_file} ${_container_arg} ${_local_file})
                logger_info "Dump pod ${_pod} file done."
                _count=$[_count+1]
            done
        done
    done;
    logger_info "Dump ${_count} files/dirs done."
}

## Package files into zip
function package_zip()
{
    ## package container files to a zip file
    ZIP_FILE=${BACKUP_PATH_PODFILE}/podfiles_${SUB_PATH}.tar
    logger_info "Package container files into zip file..."
    cd ${BACKUP_PATH_PODFILE}
    tar -cvPf ${ZIP_FILE} ${SUB_PATH}
    gzip ${ZIP_FILE}
    logger_info "Package container files into zip file: ${ZIP_FILE}.gz done."
}

## Dump container's files 
dump_container_files;

## Package files into zip
package_zip;
