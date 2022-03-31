#!/bin/bash


readonly PREWARM_DB=$1
readonly PREWARM_USER=$2
readonly PREWARM_PORT=$3

readonly TABLE_LIST=" bmsql_config
 bmsql_config_pkey
 bmsql_customer
 bmsql_customer_idx1
 bmsql_customer_pkey
 bmsql_district
 bmsql_district_pkey
 bmsql_hist_id_seq
 bmsql_history
 bmsql_history_pkey
 bmsql_item
 bmsql_item_pkey
 bmsql_new_order
 bmsql_new_order_pkey
 bmsql_oorder
 bmsql_oorder_idx1
 bmsql_oorder_pkey
 bmsql_order_line
 bmsql_order_line_pkey
 bmsql_stock
 bmsql_stock_pkey
 bmsql_warehouse
 bmsql_warehouse_pkey"

for TABLE in ${TABLE_LIST}
do
    echo "pg_prewarm ${TABLE}"
    ltsql -d ${PREWARM_DB} -U ${PREWARM_USER} -p ${PREWARM_PORT} -tc "select pg_prewarm('${TABLE}')"
done
