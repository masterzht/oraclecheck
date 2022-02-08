DEF user = 'qtune';

SET DEF ON ECHO ON VER ON

DROP USER &&user. CASCADE;
CREATE USER &&user. IDENTIFIED BY &&user.;

GRANT CREATE JOB                    TO &&user.;
GRANT ALTER  SESSION                TO &&user.;
GRANT CREATE PROCEDURE              TO &&user.;
GRANT CREATE SEQUENCE               TO &&user.;
GRANT CREATE SESSION                TO &&user.;
GRANT CREATE SYNONYM                TO &&user.;
GRANT CREATE TABLE                  TO &&user.;
GRANT CREATE VIEW                   TO &&user.;
GRANT CREATE TYPE                   TO &&user.;
GRANT CREATE DATABASE LINK          TO &&user.;

GRANT SQLT_USER_ROLE TO &&user.;

ALTER USER &&user. DEFAULT TABLESPACE users;
ALTER USER &&user. QUOTA UNLIMITED ON users;
ALTER USER &&user. TEMPORARY TABLESPACE temp;

ALTER USER &&user. DEFAULT TABLESPACE big_perm;
ALTER USER &&user. QUOTA UNLIMITED ON big_perm;
ALTER USER &&user. TEMPORARY TABLESPACE big_temp;

--GRANT DBA TO &&user.;
