REM $Header: xplore/sys_views.sql 11.4.3.2 2011/07/09 carlos.sierra $

CREATE OR REPLACE VIEW sys.sqlt$_v$parameter_cbo AS
WITH cbo_param AS (
SELECT /*+ materialize */
       pname_qksceserow name
  FROM x$qksceses
 WHERE sid_qksceserow = SYS_CONTEXT('USERENV', 'SID')
)
SELECT x.indx+1 num,
       x.ksppinm name,
       x.ksppity type,
       y.ksppstvl value,
       y.ksppstdvl display_value,
       y.ksppstdf isdefault,
       DECODE(BITAND(x.ksppiflg/256, 1), 1, 'TRUE', 'FALSE') isses_modifiable,
       DECODE(BITAND(x.ksppiflg/65536, 3), 1, 'IMMEDIATE', 2, 'DEFERRED', 3, 'IMMEDIATE', 'FALSE') issys_modifiable,
       DECODE(BITAND(x.ksppiflg, 4), 4, 'FALSE', DECODE(BITAND(x.ksppiflg/65536, 3), 0, 'FALSE', 'TRUE')) isinstance_modifiable,
       DECODE(BITAND(y.ksppstvf, 7), 1, 'MODIFIED', 4,'SYSTEM_MOD', 'FALSE') ismodified,
       DECODE(BITAND(y.ksppstvf, 2), 2, 'TRUE', 'FALSE') isadjusted,
       DECODE(BITAND(x.ksppilrmflg/64, 1), 1, 'TRUE', 'FALSE') isdeprecated,
       DECODE(BITAND(x.ksppilrmflg/268435456, 1), 1, 'TRUE', 'FALSE') isbasic,
       x.ksppdesc description,
       y.ksppstcmnt update_comment,
       x.ksppihash hash
  FROM x$ksppi x,
       x$ksppcv y,
       cbo_param
 WHERE x.indx = y.indx
   AND BITAND(x.ksppiflg, 268435456) = 0
   AND TRANSLATE(x.ksppinm, '_', '#') NOT LIKE '##%'
   AND x.ksppinm = cbo_param.name
   AND x.inst_id = USERENV('Instance');

GRANT SELECT ON sys.sqlt$_v$parameter_cbo TO PUBLIC;

CREATE OR REPLACE PUBLIC SYNONYM sqlt$_v$parameter_cbo FOR sys.sqlt$_v$parameter_cbo;

/*******************/

CREATE OR REPLACE VIEW sys.sqlt$_v$parameter_exadata AS
SELECT x.indx+1 num,
       x.ksppinm name,
       x.ksppity type,
       y.ksppstvl value,
       y.ksppstdvl display_value,
       y.ksppstdf isdefault,
       DECODE(BITAND(x.ksppiflg/256, 1), 1, 'TRUE', 'FALSE') isses_modifiable,
       DECODE(BITAND(x.ksppiflg/65536, 3), 1, 'IMMEDIATE', 2, 'DEFERRED', 3, 'IMMEDIATE', 'FALSE') issys_modifiable,
       DECODE(BITAND(x.ksppiflg, 4), 4, 'FALSE', DECODE(BITAND(x.ksppiflg/65536, 3), 0, 'FALSE', 'TRUE')) isinstance_modifiable,
       DECODE(BITAND(y.ksppstvf, 7), 1, 'MODIFIED', 4,'SYSTEM_MOD', 'FALSE') ismodified,
       DECODE(BITAND(y.ksppstvf, 2), 2, 'TRUE', 'FALSE') isadjusted,
       DECODE(BITAND(x.ksppilrmflg/64, 1), 1, 'TRUE', 'FALSE') isdeprecated,
       DECODE(BITAND(x.ksppilrmflg/268435456, 1), 1, 'TRUE', 'FALSE') isbasic,
       x.ksppdesc description,
       y.ksppstcmnt update_comment,
       x.ksppihash hash
  FROM x$ksppi x,
       x$ksppcv y
 WHERE x.indx = y.indx
   AND BITAND(x.ksppiflg, 268435456) = 0
   AND TRANSLATE(x.ksppinm, '_', '#') NOT LIKE '##%'
   AND x.ksppinm IN (
       '_bloom_filter_enabled',
       '_bloom_folding_enabled',
       '_bloom_minmax_enabled',
       '_bloom_predicate_enabled',
       '_bloom_predicate_pushdown_to_storage',
       '_bloom_pruning_enabled',
       '_bloom_pushing_max',
       '_bloom_vector_elements',
       '_cell_storidx_mode',
       '_kcfis_cell_passthru_enabled',
       '_kcfis_control1',
       '_kcfis_control2',
       '_kcfis_dump_corrupt_block',
       '_kcfis_kept_in_cellfc_enabled',
       '_kcfis_rdbms_blockio_enabled',
       '_kcfis_storageidx_disabled',
       '_projection_pushdown',
       '_projection_pushdown',
       '_slave_mapping_enabled',
       'cell_offload_processing',
       'parallel_force_local'
       )
   AND x.inst_id = USERENV('Instance');

GRANT SELECT ON sys.sqlt$_v$parameter_exadata TO PUBLIC;

CREATE OR REPLACE PUBLIC SYNONYM sqlt$_v$parameter_exadata FOR sys.sqlt$_v$parameter_exadata;

/*******************/

CREATE OR REPLACE VIEW sys.sqlt$_v$parameter_lov AS
SELECT name_kspvld_values name,
       value_kspvld_values value,
       DECODE(isdefault_kspvld_values, 'FALSE', 'FALSE', 'TRUE') isdefault
  FROM x$kspvld_values;

GRANT SELECT ON sys.sqlt$_v$parameter_lov TO PUBLIC;

CREATE OR REPLACE PUBLIC SYNONYM sqlt$_v$parameter_lov FOR sys.sqlt$_v$parameter_lov;
