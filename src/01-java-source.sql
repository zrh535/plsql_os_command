/*
 * 01-java-source.sql
 *
 * DATABASE VERSION:
 *    12c Release 1 (12.1.0.x)
 *
 * DESCRIPTION:
 *    Java helper classes for accessing the operating system from the SQL layer
 *    + FILE_TYPE_JAVA (Java class "FileType")
 *    + OS_HELPER      (Java class "ExternalCall")
 *
 *    See the documentation and README files vor more information
 *
 * AUTHOR:
 *    Carsten Czarski (carsten.czarski@gmx.de)
 *
 * VERSION:
 *    1.0
 *
 * CHANGES
 *   2010-07-21: Fixed IllegalThreadStateException when stdout is not being retrieved by the user
 */

set define off

prompt ... java source FILE_TYPE

@java/file_type_java.java
sho err

prompt ... java source OS_COMMAND

@java/os_helper.java
sho err
