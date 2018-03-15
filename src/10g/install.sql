set define off
set echo off
set timing off
set feedback off

prompt *
prompt *      **      ******  
prompt *    ****    **      **
prompt *      **    **      **    ******
prompt *      **    **      **  **     **
prompt *      **    **      **    ******* 
prompt *      **    **      **         **
prompt *    ******    ******    *******
prompt *
prompt

prompt *************************************************
prompt ** 1. Installing Java Code ...
prompt **

@01-java-source.sql

prompt *************************************************
prompt ** 2. PL/SQL Package Specs
prompt **
@02-plsql-spec.sql

prompt *************************************************
prompt ** 3. PL/SQL Package Bodys
prompt **
@03-plsql-body.sql

set feedback on
set timing on
