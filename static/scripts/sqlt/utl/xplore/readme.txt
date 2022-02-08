xplore 11.4.5.7 2013/04/05 carlos.sierra

Toggles CBO init.ora and fix control parameters to discover plans


When to use:
~~~~~~~~~~~
Use xplore only when ALL these conditions are met:
1. SQL performs poorly or returns wrong results while using a bad plan.
2. The bad plan can be reproduced on a test system (no data is preferred).
3. A good plan can be reproduced on the test system by switching OFE.
4. You need to narrow reason to specific parameter or bug fix control.
5. You have full access to the test system, including SYS access.


When NOT to use:
~~~~~~~~~~~~~~~
Do not use xplore when ANY of these conditions is true:
1. The SQL statement may cause corruption or update data.
2. There is high volume of data in tables referenced by SQL.
3. The execution of the SQL may take longer than a few seconds.


Install:
~~~~~~~
1. Connect as SYS and execute install script:

   # sqlplus / as sysdba
   SQL> START install.sql

   Notes:
   a. You will be asked for the test case user and password.
   b. Test case user should exist already. Include suffix if any.
   c. XPLORE has no dependencies on SQLT.


Use:
~~~
1. Set the CBO environment ONLY if needed to reproduce the bad plan.

   Notes:
   You may need to issue some ALTER SESSION commands.
   For example: STATISTICS_LEVEL or "_COMPLEX_VIEW_MERGING".
   The CBO environment will then be captured into a baseline.
   The baseline is executed before each test.

   # sqlplus <user>
   SQL> ALTER SESSION SET STATISTICS_LEVEL = ALL; -- example

2. Generate the xplore_script in the same session within which you executed step one.

   SQL> START create_xplore_script.sql

   Notes:
   It will ask for 5 inline parameters. You can specify XECUTE or
   XPLAIN method. You will be asked if you want to include parameters
   for CBO, Exadata and/or Fix Control. If using XECUTE you may also
   request SQL Monitor Reports with each test.

3. Execute generated xplore_script. It will ask for two parameters:

   P1. Name of the script to be executed.

       Notes:
       When using XECUTE method, your SQL must include comment
       /* ^^unique_id */ in the first few lines of your sql text.
       Example:
       SELECT /* ^^unique_id */ t1.col1, etc.

   P2. Password for <user>

4. After you are done using XPLORE you may want to bounce the
   database since it executed some ALTER SYSTEM commands:

   # sqlplus / as sysdba
   SQL> shutdown immediate
   SQL> startup


Uninstall:
~~~~~~~~~
1. Connect as SYS and execute uninstall script:

   # sqlplus <user>
   SQL> START uninstall.sql

   Note:
   You will be asked for the test case user.


Feedback:
~~~~~~~~
carlos.sierra@oracle.com
