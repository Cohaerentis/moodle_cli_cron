#!/bin/bash

root_path() {
   SOURCE="${BASH_SOURCE[0]}"
   DIR="$( dirname "$SOURCE" )"
   while [ -h "$SOURCE" ]
   do
     SOURCE="$( readlink "$SOURCE" )"
     [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd )"
   done
   DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

   $ECHO_BIN "$DIR"
}

old_files_rm () {
   local PATH=$1
   local DAYS=$2
   local file=

   if [ -n "$PATH" ] && [ -n "$DAYS" ]; then
      $ECHO_BIN "Deleting files from '$PATH' older than $DAYS days" >> $CRON_LOG_FILE
      $FIND_BIN "$PATH" -type f -mtime +$DAYS | while read file
      do
         $RM_BIN "$file"
      done
   else
      $ECHO_BIN "ERROR : Bad parameters in 'old_files_rm' PATH = '$PATH', DAYS = '$DAYS'" >> $CRON_LOG_FILE
   fi
}

log_start_print() {
   $ECHO_BIN "----------------------------------------------------------------" > $CRON_LOG_FILE;
   $ECHO_BIN -n "MOODLE CRON START - " >> $CRON_LOG_FILE;
   $ECHO_BIN $CRON_START_DATE >> $CRON_LOG_FILE;
   $ECHO_BIN "----------------------------------------------------------------" >> $CRON_LOG_FILE;
   $ECHO_BIN >> $CRON_LOG_FILE;
}

log_end_print() {
   CRON_END_DATE=`$DATE_BIN`
   $ECHO_BIN >> $CRON_LOG_FILE;
   $ECHO_BIN "----------------------------------------------------------------" >> $CRON_LOG_FILE;
   $ECHO_BIN -n "MOODLE CRON END   - " >> $CRON_LOG_FILE;
   $ECHO_BIN $CRON_END_DATE >> $CRON_LOG_FILE;
   $ECHO_BIN "----------------------------------------------------------------" >> $CRON_LOG_FILE;
}

PHP_BIN='/usr/bin/php'
MKDIR_BIN='/bin/mkdir'
ECHO_BIN='/bin/echo'
FIND_BIN='/usr/bin/find'
RM_BIN='/bin/rm'
DATE_BIN='/bin/date'

# CRON_PATH=`root_path`
CRON_PATH=`dirname $0`
CRON_START_DATE=`$DATE_BIN`
CRON_DATE=`$DATE_BIN +%F_%T | tr -d ':'`
CRON_LOG_PATH="$CRON_PATH/data/logs/cron"
CRON_LOG_FILE="$CRON_LOG_PATH/${CRON_DATE}-cron.log"

# Create log directory if not exists
if [ ! -d "$CRON_PATH/data/logs/cron" ]; then $MKDIR_BIN -p "$CRON_PATH/data/logs/cron"; fi

# Start log
log_start_print

# Removing old cron logs files
old_files_rm "$CRON_LOG_PATH" 30

# Execute cron
cd "$CRON_PATH/current/admin/cli"
if ! $PHP_BIN cron.php 2>> $CRON_LOG_FILE >> $CRON_LOG_FILE; then
   $ECHO_BIN "MOODLE CRON ERROR: Please read '$CRON_LOG_FILE' for details"
   log_end_print
   exit 1
fi

log_end_print
exit 0
