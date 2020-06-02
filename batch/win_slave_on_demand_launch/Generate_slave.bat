@ECHO OFF

set jenkins=%1

set slaveIP=%2

echo "running: %jenkins%/computer/%slaveIP%/slave-agent.jnlp"

echo "C:\Program Files (x86)\Java\jre7\bin\javaws" %jenkins%/computer/%slaveIP%/slave-agent.jnlp > slave.bat

xcopy /s /y slave.bat D:\CI\CI_TOOL

start D:\CI\CI_TOOL\slave.bat

exit