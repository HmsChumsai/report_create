#!/bin/bash
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export RPT_GROUP="preconfirm_report"
export RPT_BROKER="TSC"
export RPT_NAME="TSC-D5"
export RPT_VERSION="v51A8-001"


. ${ROOT_DIR}/TSC-D5.cfg 
. ${ROOT_DIR}/../../../../../etc/report_config.sh
. ${ROOT_DIR}/../../../../../util/functionUtils.sh

UTIL_DIR="${ROOT_DIR}/../../../../../util"


createOutDir

DECIDE_PARAM="$@" 
REPORT_PARAM="${DECIDE_PARAM} --logFile ${LOG_FILE} --dbFile ${DB_FILE}"
printLog "DECIDE param : ${DECIDE_PARAM}" | addLogPrevix | $LOGGER "$LOG_FILE" 

#Create Database file
$LUA ${ROOT_DIR}/${RPT_NAME}.lua ${REPORT_PARAM} 2>&1 | addLogPrevix | $LOGGER "$LOG_FILE" 

if [ -e ${DB_FILE} ]; then

$GEN_REPORT_SCRIPT 2>&1 | addLogPrevix | $LOGGER "$LOG_FILE"

fi


OUT_FORMAT=`echo $RPT_FORMAT | awk '{print \$1}'`
OUT_RPT_FILE=""

case $OUT_FORMAT in 

   "PDF")
   OUT_RPT_FILE=${PDF_FILE}
   ;;

   "CSV")
   OUT_RPT_FILE=${CSV_FILE}
   ;;

   "TXT")
   OUT_RPT_FILE=${TXT_FILE}
   ;;

   "HTML")
   OUT_RPT_FILE=${HTML_FILE}
   ;;

   "XML")
   OUT_RPT_FILE=${XML_FILE}
   ;;

   "EXCEL")
   OUT_RPT_FILE=${EXCEL_FILE}
   ;;

   "XLS")
   OUT_RPT_FILE=${XLS_FILE}
   ;;

   "JCSV")
   OUT_RPT_FILE=${JCSV_FILE}
   ;;

   "JPSV")
   OUT_RPT_FILE=${JPSV_FILE}
   ;;

   "JTXT")
   OUT_RPT_FILE=${JTXT_FILE}
   ;;

   *)
   OUT_RPT_FILE=""
   ;;

esac


case $RPT_DISPLAY in 

   "CALLBACK")

          if [ -f ${OUT_RPT_FILE} ]; then
              SUCCESS_MESSAGE=" Successed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${SUCCESS_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
              $LUA ${UTIL_DIR}/CallbackDECIDE.lua --success "yes" --file ${OUT_RPT_FILE}
          else
              ERROR_MESSAGE=" Failed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${ERROR_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
              $LUA ${UTIL_DIR}/CallbackDECIDE.lua --success "no" --reason ${ERROR_MESSAGE}
          fi
   ;;

   "ECHO")
          if [ -f ${OUT_RPT_FILE} ]; then
              SUCCESS_MESSAGE=" Successed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${SUCCESS_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
              echo -n ${OUT_RPT_FILE}
          else
              ERROR_MESSAGE=" Failed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${ERROR_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
              echo -n ${ERROR_MESSAGE}
          fi
   ;;

   "NO")
          if [ -f ${OUT_RPT_FILE} ]; then
              SUCCESS_MESSAGE=" Successed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${SUCCESS_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
          else
              ERROR_MESSAGE=" Failed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${ERROR_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
          fi
   ;;

   "*")
          if [ -f ${OUT_RPT_FILE} ]; then
              SUCCESS_MESSAGE="[Invalid RPT_DISPLAY : <${RPT_DISPLAY}> ] Successed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${SUCCESS_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
          else
              ERROR_MESSAGE="[Invalid RPT_DISPLAY : <${RPT_DISPLAY}> ] Failed to generate report <${RPT_NAME}> <${RPT_VERSION}> "
              printLog  ${ERROR_MESSAGE} | addLogPrevix | $LOGGER "$LOG_FILE" 
          fi
  ;;


esac 



