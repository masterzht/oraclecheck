-- execute sqlt xecute as apps passing script name
-- cd sqlt
-- #sqlplus apps
-- SQL> start run/sqltxecute.sql input/sample/script3.sql

VAR   A00                             VARCHAR2(2000);
VAR   A01                             VARCHAR2(2000);
VAR   A02                             VARCHAR2(2000);
VAR   A03                             VARCHAR2(2000);

EXEC :A00                             := '7171';
EXEC :A01                             := 'STANDARD';
EXEC :A02                             := 'SUPERUSER-EGGS-USA';
EXEC :A03                             := '666';

SELECT
  /* ^^unique_id */
  R.APPLICATION_ID,
  R.RESPONSIBILITY_ID,
  S.SECURITY_GROUP_ID,
  R.RESPONSIBILITY_NAME,
  S.SECURITY_GROUP_NAME
FROM FND_RESPONSIBILITY_VL R,
  FND_USER_RESP_GROUPS U,
  FND_SECURITY_GROUPS_VL S
WHERE U.USER_ID = :A00
AND SYSDATE BETWEEN U.START_DATE AND NVL(U.END_DATE, SYSDATE)
AND R.VERSION          IN ('4', 'W')
AND R.APPLICATION_ID    = U.RESPONSIBILITY_APPLICATION_ID
AND R.RESPONSIBILITY_ID = U.RESPONSIBILITY_ID
AND SYSDATE BETWEEN R.START_DATE AND NVL(R.END_DATE, SYSDATE)
AND U.SECURITY_GROUP_ID                            = S.SECURITY_GROUP_ID
AND S.SECURITY_GROUP_ID                           >= 0
AND S.SECURITY_GROUP_KEY                           = NVL(:A01, S.SECURITY_GROUP_KEY)
AND R.RESPONSIBILITY_KEY                           = NVL(:A02, R.RESPONSIBILITY_KEY)
AND R.APPLICATION_ID                               = NVL(:A03, R.APPLICATION_ID)
AND NVL(FND_PROFILE.VALUE('NODE_TRUST_LEVEL'), 1) <= NVL(FND_PROFILE.VALUE_SPECIFIC('APPL_SERVER_TRUST_LEVEL', U.USER_ID,R.RESPONSIBILITY_ID,R.APPLICATION_ID),1)
ORDER BY RESPONSIBILITY_NAME,
  SECURITY_GROUP_NAME;
/
/
