@ECHO OFF

set JAR_NAME=iep-node.jar
for /f "tokens=2 USEBACKQ" %f IN (`tasklist /NH /FI "WINDOWTITLE eq _the_jar_I_want_to_close_*"`) Do set task_id=%f
ECHO "Stopping XIN node with process id"
taskkill /F /PID %task_id%