* README.txt
* 
* DESCRIPTION:
*    Information and installation instructions 
*
* AUTHOR:
*    Carsten Czarski (carsten.czarski@gmx.de)
*
* This is a set of PLSQL packages for the Oracle database which provide access to the 
* OS shell and the file system from SQL and PL/SQL. The packages provide operations on 
* file handles (delete, create, move, copy) as well as the execution of shell commands.

* There are two installation options:

* 1. Install the packages as SYS and make it accessible to everyone
* 2. Install the packages in a "normal" database schema
*  
* In both cases the invoking user and the schema owning the packages 
* need appropriate Java privileges to use the package - the 
* "samples" folder contains some sample GRANT statements;
* these must be run with DBA privileges.
*
* REQUIREMENTS:
*  + Database version Oracle 10.2 or higher 
*  + Java in the database must be installed and enabled
* 
*    SQL> select comp_name, version from dba_registry where comp_name like '%JAVA%'
*
*    COMP_NAME                                VERSION
*    ---------------------------------------- ------------------------------
*    JServer JAVA Virtual Machine             10.2.0.4.0
*  
*  + Appropriate java_pool_size; at least 50MB 
*
* INSTALLATION:
*  start "install.sql" in SQL*Plus
*
* DEINSTALLATION STEPS:
*  start "uninstall.sql" in SQL*Plus 
* 
* PRIVILEGES:
*  After installation the user can exeute the PL/SQL package and therefore
*  the java class - but is not able to execute any OS command - this requires
*  additional privileges due to the Java 2 security model. 
*  The script "java_grants.sql" contains some sample statements for sample grants.
*  When granting JAVASYSPRIV to the respective user this user can execute
*  ANY OS command - this is a very powerful privilege and only appropriate
*  for development purposes. Production environments should only grant
*  the really needed privileges.
*


