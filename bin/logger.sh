#!/usr/bin/bash

## Define constants
LOG_LANG_ALL="zh en fr"
LOG_MSG_TEMPLATE_AFFIX="backup-msg_"
#LOG_PATH="./logs"
#LOG_OUTPUT_FILE_DEFAULT="${LOG_PATH}/backup.log"

## Define variables
LOG_DEBUG_LEVEL=0
LOG_OUTPUT_FILE=$LOG_OUTPUT_FILE_DEFAULT
LOG_OUTPUT_CONSOLE=true
LOG_LANG=en
LOG_MSG_TEMPLATE="backup-msg_${LOG_LANG}.tmpl"
TZ="Asia/Shanghai"

## Make log path
mkdir -p $LOG_PATH

## Set time zone of message
logger_set_timezone()
{
    if [ $# -ge 1 ]; then
        TZ=$1
        logger_info "Set timezone, TZ=${TZ}."
    fi
}

## Set logfile path to output 
logger_set_output()
{
    if [ $# -ge 1 ]; then
        LOG_OUTPUT_FILE=$1
    fi
}

## Set language
logger_set_lang()
{
    if [ $# -le 0 ]; then
        return;
    fi
    for lang in ${LOG_LANG_ALL}; do
        if [ ${lang} = $1 ]; then
            LOG_LANG=${lang}
            LOG_MSG_TEMPLATE="${LOG_MSG_TEMPLATE_AFFIX}${LOG_LANG}.tmpl"
        fi 
    done
}

## Logger output
logger_output_private()
{
    if [ $# -le 0 ]; then
        return;
    fi
    info_level=$1
    msg_id=$2
    shift
    millisecond=$(expr $(date +%N) / 1000)
    debug_msg_head="$(TZ=$TZ date '+%Y-%m-%d %H:%M:%S').$(printf '%06d' ${millisecond}) [$$] - ${info_level} "
    if [ "${msg_id:0:3}" = "MSG" ]; then
        shift
        pattern=$($msg_id)
        debug_msg="${debug_msg_head}""$(printf $pattern $@ )"
    else
        debug_msg="${debug_msg_head}$@"
    fi
    #debug_msg=${debug_msg_head}$(printf $2 )
    echo "${debug_msg}" >> ${LOG_OUTPUT_FILE}
    if [ ${LOG_OUTPUT_CONSOLE} = true ]; then
        echo "${debug_msg}"
    fi
}

## Logger debug 0
logger_debug()
{
    if [ ${LOG_DEBUG_LEVEL} -le 0 ]; then
        logger_output_private "DEBUG" $@
    fi
}

## Logger info 1
logger_info()
{
    if [ ${LOG_DEBUG_LEVEL} -le 1 ]; then
        logger_output_private "INFO" $@
    fi
}

## Logger warn 2
logger_warn()
{
    if [ ${LOG_DEBUG_LEVEL} -le 2 ]; then
        logger_output_private "WARN" $@
    fi
}

## Logger warn 3
logger_error()
{
    if [ ${LOG_DEBUG_LEVEL} -le 3 ]; then
        logger_output_private "ERROR" $@
    fi
}

## Logger alert 4
logger_alert()
{
    if [ ${LOG_DEBUG_LEVEL} -le 4 ]; then
        logger_output_private "ALERT" $@
    fi
}

## Logger fatal 5
logger_fatal()
{
    if [ ${LOG_DEBUG_LEVEL} -le 5 ]; then
        logger_output_private "FATAL" $@
    fi
}
