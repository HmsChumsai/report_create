#!/bin/bash
TEST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export RPT_NAME=`echo ${TEST_DIR} |awk -F_v '{print \$1}' |awk -F/ '{print \$NF}'`
export RPT_VERSION=`echo ${TEST_DIR} |awk -F_v '{print \$2}' |awk -F/ '{print \$1}'`
export DECIDESPACE="HKTHX-3"

if [ "$1" != "" ]; then

DECIDESPACE=$1

fi

# =============================================================
export SPACE_NAME="${DECIDESPACE}"
export BROKER_CODE=""
export BROKER=""
export SPACE_PREFIX=`echo $SPACE_NAME| cut -d'-' -f 1`

case "$SPACE_PREFIX" in

"BKKTSC")  BROKER="TSC" 
           BROKER_CODE="0002"
;;
"BKKCNS")  BROKER="CNS" 
           BROKER_CODE="0014"
;;
"BKKASP")  BROKER="ASP" 
           BROKER_CODE="0008"
;;
"BKKAWS")  BROKER="AWS" 
           BROKER_CODE="0043"
;;
"BKKSCBS") BROKER="SCBS" 
           BROKER_CODE="0023"
;;
"HKTHX")   BROKER="SSLTD" 
           BROKER_CODE="9999"
;;
*) BROKER="" ;;

esac

export RPT_BROKER="${BROKER}"

# =============================================================

. ${TEST_DIR}/../bin/${RPT_NAME}.cfg 
. ${TEST_DIR}/../../../../etc/report_config.sh
. ${TEST_DIR}/env.cfg
. ${TEST_DIR}/../../../../util/functionUtils.sh

HEAD_BANNER="${DECIDESPACE} Start to generate : <${RPT_NAME}> <${RPT_VERSION}>"
echo
echo " ${HEAD_BANNER} "
printLog ${HEAD_BANNER} | addLogPrevix | $LOGGER "$LOG_FILE" 


createOutDir

DECIDE_PARAM="$@" 
REPORT_PARAM="${DECIDE_PARAM} --logFile ${LOG_FILE} --dbFile ${DB_FILE}"
printLog "DECIDE param : ${DECIDE_PARAM}" | addLogPrevix | $LOGGER "$LOG_FILE" 

#Create Database file
$LUA ../bin/${RPT_NAME}.lua ${REPORT_PARAM} 2>&1 | addLogPrevix | $LOGGER "$LOG_FILE" 

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


if [ -f $OUT_RPT_FILE ]; then

  echo " Successed to generate report : <${RPT_NAME}> <${RPT_VERSION}>. "
  echo " PATH : ${OUT_RPT_FILE} "
  echo

  exit 0

else

  echo " Failed to generate report : <${RPT_NAME}> <${RPT_VERSION}>. "
  echo
  exit 9

fi















