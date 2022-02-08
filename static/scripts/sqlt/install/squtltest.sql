COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._10_squtltest.log;
SET TERM OFF ECHO ON APPI OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 215187.1 squtltest.sql 11.4.5.7 2013/04/05 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/squtltest.sql
REM
REM DESCRIPTION
REM   Tests that UTL_FILE works properly as required by SQLT
REM   to read and write files in designated directories.
REM
REM PRE-REQUISITES
REM   1. To test UTL_FILE you must be connected as a user granted
REM      the SQLT_USER_ROLE.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory
REM   2. Start SQL*Plus connecting as user granted SQLT_USER_ROLE.
REM   3. Execute script squtltest.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus user/pwssword
REM   SQL> START squtltest.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcreate.sql
REM   2. If installing in RAC, perform the installation locally
REM      and run SQLT from the same node where it was installed.
REM   3. For possible errors see squtltest.log file
REM
SET ECHO OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
  PROCEDURE open_write_close (
    p2_location IN VARCHAR2,
    p2_filename IN VARCHAR2 )
  IS
    out_file_type UTL_FILE.file_type;
  BEGIN
    SYS.DBMS_OUTPUT.PUT_LINE('Test WRITING into file "'||p2_filename||'" in directory "'||p2_location||'" started.');
    out_file_type :=
    SYS.UTL_FILE.FOPEN (
       location     => p2_location,
       filename     => p2_filename,
       open_mode    => 'WB',
       max_linesize => 32767 );

    SYS.UTL_FILE.PUT_RAW (
      file   => out_file_type,
      buffer => SYS.UTL_RAW.CAST_TO_RAW('Hello World!'||CHR(10)));

    SYS.UTL_FILE.FCLOSE(file => out_file_type);
    SYS.DBMS_OUTPUT.PUT_LINE('Test WRITING into file "'||p2_filename||'" in directory "'||p2_location||'" completed.');
  END open_write_close;

  PROCEDURE open_read_close (
    p2_directory_alias IN VARCHAR2,
    p2_file_name IN VARCHAR2 )
  IS
    l_file BFILE;
    l_file_len INTEGER := NULL;
    l_file_offset INTEGER;
    l_chunk_raw RAW(32767);
    l_chunk VARCHAR2(32767);
  BEGIN
    SYS.DBMS_OUTPUT.PUT_LINE('Test READING file "'||p2_file_name||'" from directory "'||p2_directory_alias||'" started.');
    l_file := BFILENAME(p2_directory_alias, p2_file_name);
    SYS.DBMS_LOB.FILEOPEN (file_loc => l_file);
    l_file_len := SYS.DBMS_LOB.GETLENGTH(file_loc => l_file);
    l_file_offset := 1;

    SYS.DBMS_LOB.READ (
      file_loc => l_file,
      amount   => l_file_len,
      offset   => l_file_offset,
      buffer   => l_chunk_raw );

    l_chunk := SYS.UTL_RAW.CAST_TO_VARCHAR2 (r => l_chunk_raw);
    SYS.DBMS_LOB.FILECLOSE (file_loc => l_file);
    SYS.DBMS_OUTPUT.PUT_LINE('Test READING file "'||p2_file_name||'" from directory "'||p2_directory_alias||'" completed.');
  END open_read_close;

  PROCEDURE read_attributes (
    p2_directory_alias IN VARCHAR2,
    p2_file_name IN VARCHAR2 )
  IS
    l_file_exists     BOOLEAN;
    l_file_length     NUMBER;
    l_file_block_size NUMBER;
  BEGIN
    SYS.UTL_FILE.FGETATTR (
      location     => p2_directory_alias,
      filename     => p2_file_name,
      fexists      => l_file_exists,
      file_length  => l_file_length,
      block_size   => l_file_block_size );

    IF l_file_exists THEN
      SYS.DBMS_OUTPUT.PUT_LINE('File "'||p2_file_name||'" exists in directory "'||p2_directory_alias||'".');
    ELSE
      SYS.DBMS_OUTPUT.PUT_LINE('File "'||p2_file_name||'" does not exists in directory "'||p2_directory_alias||'".');
      RAISE_APPLICATION_ERROR(-20100, 'Install failed - UTL_FILE.FGETATTR not capable of reading file attributes.');
    END IF;
  END read_attributes;
BEGIN
  open_write_close('SQLT$STAGE', 'squtltest.txt');
  open_read_close('SQLT$STAGE', 'squtltest.txt');
  read_attributes('SQLT$STAGE', 'squtltest.txt');

  SYS.DBMS_OUTPUT.PUT_LINE('SQLT UTL_FILE WRITE/READ Test passed!');
END;
/

SET TERM ON;
WHENEVER SQLERROR CONTINUE;
PRO
PRO SQUTLTEST completed.
SPO OFF;
