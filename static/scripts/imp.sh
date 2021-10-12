
#!/bin/bash
export ORACLE_HOME=/home/oracle
export ORACLE_SID=orcl



sqlplus / as sysdba <<EOF
@tpch_orders.sql
EOF
