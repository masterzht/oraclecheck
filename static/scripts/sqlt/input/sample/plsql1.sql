REM Sample PL/SQL block to be used as input to sqltxecute.sql
REM

declare
  v_junk VARCHAR2(1);
begin
  select dummy /*+ ^^unique_id */
    into v_junk from dual;
end;
/

REM Notes:
REM 1. SQLT XECUTE will analyze the SQL statement that
REM    includes token /*+ ^^unique_id */ in any place.
REM 2. Token /*+ ^^unique_id */ is not a CBO Hint. Thus
REM    it does not have to be placed right after the
REM    SELECT. But it must follow the same Hint syntax.
REM    Ex: /*+ ^^unique_id */  or --+ ^^unique_id
REM 3. Script must be able to execute stand-alone. Example:
REM    SQL> START plsql1.sql
REM 4. Script can contain ALTER SESSION commands.
