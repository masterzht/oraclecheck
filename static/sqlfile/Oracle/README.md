
```
主要功能：
1、Oracle巡检(请给予可执行权限并用oracle用户执行)
2、MySQL巡检
3、PostgreSQL巡检
4、informix巡检
5、MySQL一键安装(请用root用户执行)
6、Oracle一键安装(暂时只支持单实例安装)
7、一键MySQL主从
8、MySQL慢日志分析
9、MySQL binlog2sql工具使用
10、
**若果想使用binlog2sql功能需要在执行start程序后指定位置参数**
eg:

./start -uroot -p123456 --start-file='bin.000005' --stop-file='bin.000005'
./start -uroot -p123456 --start-file='bin.000005' --stop-file='bin.000005' --only-dml
./start -uroot -p123456 --start-file='bin.000005' --stop-file='bin.000005' --flashback
usage: start.py [-h HOST] [-u USER] [-p [PASSWORD [PASSWORD ...]]] [-P PORT]
               [--start-file START_FILE] [--start-position START_POS]
               [--stop-file END_FILE] [--stop-position END_POS]
               [--start-datetime START_TIME] [--stop-datetime STOP_TIME]
               [--stop-never] [--help] [-d [DATABASES [DATABASES ...]]]
               [-t [TABLES [TABLES ...]]] [--only-dml]
               [--sql-type [SQL_TYPE [SQL_TYPE ...]]] [-K] [-B]
               [--back-interval BACK_INTERVAL]

Parse MySQL binlog to SQL you want

optional arguments:
  --stop-never          Continuously parse binlog. default: stop at the latest
                        event when you start.
  --help                help information
  -K, --no-primary-key  Generate insert sql without primary key if exists
  -B, --flashback       Flashback data to start_position of start_file
  --back-interval BACK_INTERVAL
                        Sleep time between chunks of 1000 rollback sql. set it
                        to 0 if do not need sleep

connect setting:
  -h HOST, --host HOST  Host the MySQL database server located
  -u USER, --user USER  MySQL Username to log in as
  -p [PASSWORD [PASSWORD ...]], --password [PASSWORD [PASSWORD ...]]
                        MySQL Password to use
  -P PORT, --port PORT  MySQL port to use

interval filter:
  --start-file START_FILE
                        Start binlog file to be parsed
  --start-position START_POS, --start-pos START_POS
                        Start position of the --start-file
  --stop-file END_FILE, --end-file END_FILE
                        Stop binlog file to be parsed. default: '--start-file'
  --stop-position END_POS, --end-pos END_POS
                        Stop position. default: latest position of '--stop-
                        file'
  --start-datetime START_TIME
                        Start time. format %Y-%m-%d %H:%M:%S
  --stop-datetime STOP_TIME
                        Stop Time. format %Y-%m-%d %H:%M:%S;

schema filter:
  -d [DATABASES [DATABASES ...]], --databases [DATABASES [DATABASES ...]]
                        dbs you want to process
  -t [TABLES [TABLES ...]], --tables [TABLES [TABLES ...]]
                        tables you want to process

type filter:
  --only-dml            only print dml, ignore ddl
  --sql-type [SQL_TYPE [SQL_TYPE ...]]
                        Sql type you want to process, support INSERT, UPDATE, DELETE.

```
