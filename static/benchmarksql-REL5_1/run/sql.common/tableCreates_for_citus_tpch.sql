CREATE TABLE customer (
                                 c_custkey numeric NOT NULL,
                                 c_mktsegment bpchar(10) NULL,
                                 c_nationkey numeric NULL,
                                 c_name varchar(25) NULL,
                                 c_address varchar(40) NULL,
                                 c_phone bpchar(15) NULL,
                                 c_acctbal numeric NULL,
                                 c_comment varchar(118) NULL
);


SELECT create_reference_table('bmsql_config');

CREATE TABLE lineitem (
                                 l_shipdate timestamp NULL,
                                 l_orderkey numeric NOT NULL,
                                 l_discount numeric NOT NULL,
                                 l_extendedprice numeric NOT NULL,
                                 l_suppkey numeric NOT NULL,
                                 l_quantity numeric NOT NULL,
                                 l_returnflag bpchar(1) NULL,
                                 l_partkey numeric NOT NULL,
                                 l_linestatus bpchar(1) NULL,
                                 l_tax numeric NOT NULL,
                                 l_commitdate timestamp NULL,
                                 l_receiptdate timestamp NULL,
                                 l_shipmode bpchar(10) NULL,
                                 l_linenumber numeric NOT NULL,
                                 l_shipinstruct bpchar(25) NULL,
                                 l_comment varchar(44) NULL
);
SELECT create_distributed_table('bmsql_warehouse', 'w_id');

CREATE TABLE nation (
                               n_nationkey numeric NOT NULL,
                               n_name bpchar(25) NULL,
                               n_regionkey numeric NULL,
                               n_comment varchar(152) NULL
);
SELECT create_reference_table('nation');


CREATE TABLE public.orders (
                               o_orderdate timestamp NULL,
                               o_orderkey numeric NOT NULL,
                               o_custkey numeric NOT NULL,
                               o_orderpriority bpchar(15) NULL,
                               o_shippriority numeric NULL,
                               o_clerk bpchar(15) NULL,
                               o_orderstatus bpchar(1) NULL,
                               o_totalprice numeric NULL,
                               o_comment varchar(79) NULL
);

SELECT create_distributed_table('bmsql_customer', 'c_w_id',colocate_with => 'bmsql_warehouse');


create sequence bmsql_hist_id_seq;

CREATE TABLE public.part (
                             p_partkey numeric NOT NULL,
                             p_type varchar(25) NULL,
                             p_size numeric NULL,
                             p_brand bpchar(10) NULL,
                             p_name varchar(55) NULL,
                             p_container bpchar(10) NULL,
                             p_mfgr bpchar(25) NULL,
                             p_retailprice numeric NULL,
                             p_comment varchar(23) NULL
);
SELECT create_distributed_table('bmsql_history', 'h_w_id',colocate_with => 'bmsql_warehouse');


CREATE TABLE public.partsupp (
                                 ps_partkey numeric NOT NULL,
                                 ps_suppkey numeric NOT NULL,
                                 ps_supplycost numeric NOT NULL,
                                 ps_availqty numeric NULL,
                                 ps_comment varchar(199) NULL
);
SELECT create_distributed_table('bmsql_new_order', 'no_w_id',colocate_with => 'bmsql_warehouse');

CREATE TABLE region (
                               r_regionkey numeric NULL,
                               r_name bpchar(25) NULL,
                               r_comment varchar(152) NULL
);
SELECT create_reference_table('region');

CREATE TABLE supplier (
                                 s_suppkey numeric NOT NULL,
                                 s_nationkey numeric NULL,
                                 s_comment varchar(102) NULL,
                                 s_name bpchar(25) NULL,
                                 s_address varchar(40) NULL,
                                 s_phone bpchar(15) NULL,
                                 s_acctbal numeric NULL
);
SELECT create_reference_table('supplier');

