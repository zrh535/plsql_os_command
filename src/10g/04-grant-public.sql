/*
 * 04-grant-public.sql
 *
 * DATABASE VERSION:
 *    10g Release 2 (10.2.0.x)
 * 
 * DESCRIPTION:
 *    Script to make the PL/SQL Objects accessible for PUBLIC;
 *    grant execute privileges and create public synonyms.
 *
 *    See the documentation and README files vor more information
 *
 * AUTHOR:
 *    Carsten Czarski (carsten.czarski@gmx.de)
 *
 * VERSION: 
 *    0.9
 */



grant execute on java source "OS_HELPER" to public
/
grant execute on java source "FILE_TYPE_JAVA" to public
/

create public synonym "ExternalCall" for "ExternalCall"
/
create public synonym "FileType" for "FileType"
/

grant execute on "ExternalCall" to public
/
grant execute on "FileType" to public
/

grant execute on OS_COMMAND to public
/
grant execute on lob_writer_plsql to public
/
grant execute on FILE_PKG to public
/
grant execute on FILE_TYPE to public
/
grant execute on FILE_LIST_TYPE to public
/
grant execute on FILE_security to public
/

create public synonym OS_COMMAND for OS_COMMAND
/
create public synonym LOB_WRITER_PLSQL for LOB_WRITER_PLSQL
/
create public synonym FILE_PKG for FILE_PKG
/
create public synonym FILE_TYPE for FILE_TYPE
/
create public synonym file_security for file_security
/
create public synonym FILE_LIST_TYPE for FILE_LIST_TYPE
/
