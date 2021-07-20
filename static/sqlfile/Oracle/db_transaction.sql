select
    vs.sid || ','|| vs.serial# || '@' || vs.inst_id as SESSION_ID,
    vs.username,
    vs.machine,
    vs.sql_id,
    vs.event,
    vs.prev_sql_id,
    vt.status,
    vt.xidusn || ',' ||vt.xidslot || ',' || vt.xidsqn xid,
    to_char(vt.start_date,'yyyy-mm-dd hh24:mi:ss') TRX_STARTED,
    vt.log_io,
    vt.phy_io,
    vt.used_ublk,
    vt.used_urec,
    vs.inst_id,
    round((sysdate-vt.start_date)*24*3600) TRX_SECONDS,
	(select translate(substr(sql_text, 1, 20), chr(10)||chr(11)||chr(13),' ') from v$sql where sql_id = vs.sql_id and rownum = 1) sql_text,
	(select translate(substr(sql_text, 1, 20), chr(10)||chr(11)||chr(13),' ') from v$sql where sql_id = vs.sql_id and rownum = 1) prev_sql_text
from
gv$transaction vt,
gv$session vs
where   vt.addr = vs.taddr
and     vt.inst_id = vs.inst_id
order by vt.used_ublk desc;