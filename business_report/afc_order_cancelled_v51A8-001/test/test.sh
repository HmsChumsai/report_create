
TEST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export RPT_NAME=`echo ${TEST_DIR} |awk -F_v '{print \$1}' |awk -F/ '{print \$NF}'`
export RPT_BROKER="TSC"

echo " Test : <$RPT_NAME> "
#echo " TEST_DIR : ${TEST_DIR} "

. ${TEST_DIR}/../bin/${RPT_NAME}.cfg 
. ${TEST_DIR}/../../../../etc/report_config.sh
. ${TEST_DIR}/env.cfg
. ${TEST_DIR}/../../../../util/functionUtils.sh


createOutDir

DECIDE_PARAM="$@" 
REPORT_PARAM="${DECIDE_PARAM} --logFile ${LOG_FILE} --dbFile ${DB_FILE}"
printLog "DECIDE param : ${DECIDE_PARAM}" | addLogPrevix | $LOGGER "$LOG_FILE" 

#Create Database file
$LUA ../bin/${RPT_NAME}.lua ${REPORT_PARAM} 2>&1 | addLogPrevix | $LOGGER "$LOG_FILE" 

if [ -e ${DB_FILE} ]; then

$GEN_REPORT_SCRIPT 2>&1 | addLogPrevix | $LOGGER "$LOG_FILE"

if [ "${RPT_DISPLAY}" == "YES" ]; then

  RPT_DISPLAY=`echo $RPT_FORMAT | awk '{print \$1}'`

fi


if [ "${RPT_DISPLAY}" != "" ]; then

  case $RPT_FORMAT in 

        "PDF")
          echo -n $PDF_FILE
        ;;

        "CSV")
          echo -n $CSV_FILE
        ;;

        "TXT")
          echo -n $TXT_FILE
        ;;

        "HTML")
          echo -n $HTML_FILE
        ;;

        "XML")
          echo -n $XML_FILE
        ;;

        "EXCEL")
          echo -n $EXCEL_FILE
        ;;

        "XLS")
          echo -n $EXCEL_FILE
        ;;

        "JCSV")
          echo -n $JCSV_FILE
        ;;

        "JPSV")
          echo -n $JPSV_FILE
        ;;

        "JTXT")
          echo -n $JTXT_FILE
        ;;

        *)
          echo " Found invalid report format <$RPT_FORMAT> "
        ;;

  esac

else

echo "Database file not found <${DB_FILE}>"

fi




fi

