/*
 * 02-plsql-spec.sql
 *
 * DATABASE VERSION:
 *    11g Release 1 (11.1.0.x) and 11g Release 2 (11.2.0.x)
 *
 * DESCRIPTION:
 *    PL/SQL Package specifications and Object type definitions:
 *    + OS_COMMAND
 *    + FILE_PKG
 *    + LOB_WRITER_PLSQL
 *    + FILE_TYPE
 *
 *    See the documentation and README files vor more information
 *
 * AUTHOR:
 *    Carsten Czarski (carsten.czarski@gmx.de)
 *
 * VERSION:
 *    1.0
 */

prompt ... type spec FILE_TYPE

@types/file_type.tps
sho err

prompt ... package spec FILE_PKG

@packages/file_pkg.pks
sho err

prompt ... package spec OS_COMMAND

@packages/os_command.pks
sho err

prompt ... package spec LOB_WRITER_PLSQL (deprecated)

@packages/lob_writer_plsql.pks
sho err

prompt ... package spec FILE_SECURITY

@packages/file_security.pks
sho err

prompt ... package spec FILE_PKG_VERSION

@packages/file_pkg_version.pks
sho err
