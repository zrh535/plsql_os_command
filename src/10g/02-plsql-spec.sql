/*
 * 02-plsql-spec.sql
 *
 * DATABASE VERSION:
 *    10g Release 2 (10.2.0.x)
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

create type FILE_TYPE authid current_user as object 
(
  file_path      varchar2(4000),
  file_name      varchar2(4000),
  file_size      number,
  last_modified  date,
  is_dir         char(1),
  is_writeable   char(1),
  is_readable    char(1),
  file_exists    char(1),
  member function move(p_target_file in file_type) return file_type
    is language java name 'FileType.renameTo(oracle.sql.STRUCT) return oracle.sql.STRUCT',
  member function delete_file return file_type
    is language java name 'FileType.delete() return oracle.sql.STRUCT',
  member function delete_recursive return file_type
    is language java name 'FileType.deleteRecursive() return oracle.sql.STRUCT',
  member function make_file return FILE_TYPE
    is language java name 'FileType.createEmptyFile() return oracle.sql.STRUCT',
  member function make_dir return FILE_TYPE
    is language java name 'FileType.mkdir() return int',
  member function create_dir (p_dirname in varchar2) return FILE_TYPE
    is language java name 'FileType.mkdir(java.lang.String) return FileType',
  member function create_file (p_filename in varchar2) return file_type
    is language java name 'FileType.createFile(java.lang.String) return FileType',
  member function copy (p_target_file in file_type) return file_type
    is language java name 'FileType.copy(oracle.sql.STRUCT) return oracle.sql.STRUCT',
  member function make_all_dirs return file_type
    is language java name 'FileType.mkdirs() return oracle.sql.STRUCT',
  member function get_content_as_clob(p_charset in varchar2) return clob
    is language java name 'FileType.getContentCLOB(java.lang.String) return oracle.sql.CLOB',
  member function write_to_file(p_content in clob) return number
    is language java name 'FileType.writeClobToFile(oracle.sql.CLOB) return long',
  member function append_to_file(p_content in clob) return number
    is language java name 'FileType.appendClobToFile(oracle.sql.CLOB) return long',
  member function write_to_file(p_content in blob) return number
    is language java name 'FileType.writeBlobToFile(oracle.sql.BLOB) return long',
  member function append_to_file(p_content in blob) return number
    is language java name 'FileType.appendBlobToFile(oracle.sql.BLOB) return long',
  member function append_to_file(p_content in varchar2) return number
    is language java name 'FileType.appendStringToFile(java.lang.String) return long',
  member function get_content_as_blob return blob
    is language java name 'FileType.getContentBLOB() return oracle.sql.BLOB',
  member function get_parent return file_type
    is language java name 'FileType.getParent() return oracle.sql.STRUCT',
  member procedure open_stream
    is language java name 'FileType.openInputStream()',
  member procedure close_stream
    is language java name 'FileType.closeInputStream()',
  member function is_stream_open return number
    is language java name 'FileType.isStreamOpen() return int',
  member function read_bytes(p_amount in number) return raw
    is language java name 'FileType.readBytes(int) return byte[]',
  member function read_string(p_amount in number, p_charset in varchar2) return varchar2
    is language java name 'FileType.readString(int, java.lang.String) return java.lang.String',
  member function read_byte return number
    is language java name 'FileType.readByte() return int',
  member procedure skip_bytes(p_amount in number)
    is language java name 'FileType.skipBytes(long)',
 member function read_bytes(p_amount in number, p_position in number) return raw
    is language java name 'FileType.readBytes(int, long) return byte[]',
  member function read_string(p_amount in number, p_position in number, p_charset in varchar2) return varchar2
    is language java name 'FileType.readString(int, long, java.lang.String) return java.lang.String',
  member function write_bytes(p_bytes in raw, p_position in number) return number
    is language java name 'FileType.writeBytes(byte[], long) return long',
  member function write_string(p_string in varchar2, p_position in number, p_charset in varchar2) return number
    is language java name 'FileType.writeString(java.lang.String, long, java.lang.String) return long',
  static function get_file(p_file_path in varchar2) return file_type
    is language java name 'FileType.getFile(java.lang.String) return FileType',
  member function get_bfile(p_directory_name in varchar2 default null) return bfile,
  member function get_directory return varchar2
)
/
sho err

prompt ... type spec FILE_LIST_TYPE
create type file_list_type as table of file_type
/
sho err

prompt ... package spec FILE_PKG 

create or replace package file_pkg authid current_user
is
  procedure set_batch_size (p_batch_size in number default 10);
  function get_batch_size return number;

  function get_file(
    p_file_path in varchar2
  ) return file_type;
  function get_file_list(
    p_directory in file_type
  ) return file_list_type;
  function get_recursive_file_list(
    p_directory in file_type
  ) return file_list_type;
  function get_path_separator return varchar2;
  function get_root_directories return file_list_type;
  function get_root_directory return file_type;
  procedure set_fs_encoding(p_fs_encoding in varchar2);
  function get_fs_encoding return varchar2;

  /* 0.9 ## Pipelined Directory Listing */
  function get_recursive_file_list_p(p_directory in file_type)
  return file_list_type pipelined;
  function get_file_list_p (p_directory in file_type)
  return file_list_type pipelined; 

    /* 1.0 ## DIRECTORY Object integration */
  function get_file(p_directory in varchar2, p_filename in varchar2) return file_type;
  function get_file(p_bfile in bfile) return file_type;
  function get_file_list(p_directory_name in varchar2) return file_list_type;
  function get_file_list_p (p_directory_name in varchar2) return file_list_type pipelined; 

  function remove_multiple_separators(p_path in varchar2) return varchar2;
end file_pkg;
/
sho err

prompt ... package spec OS_COMMAND 

create or replace package os_command authid current_user is
  procedure set_working_dir (p_workdir in file_type);
  procedure clear_working_dir;
  function get_working_dir return FILE_TYPE;
  
  procedure clear_environment;
  procedure set_env_var(p_env_name in varchar2, p_env_value in varchar2);
  procedure remove_env_var(p_env_name in varchar2);
  function get_env_var(p_env_name in varchar2) return varchar2;
/*
 * 11g only
 *
  procedure load_env(p_env_name in varchar2);
  procedure load_env;
 */


  procedure set_Shell(p_shell_path in varchar2, p_shell_switch in varchar2);
  function get_shell return varchar2;
  procedure set_exec_in_shell;
  procedure set_exec_direct;



  procedure use_custom_env;
  procedure use_default_env;

  /* the following functions execute the command "p_command" with
   * the content of "p_stdin" for the standard input (stdin).
   */
  function exec_CLOB(p_command in varchar2, p_stdin in blob) return clob;
  /* ... for commands expecting binary input and returning text */
  function exec_CLOB(p_command in varchar2, p_stdin in clob) return clob;
  /* ... for commands expecting text input and returning text */
  function exec_BLOB(p_command in varchar2, p_stdin in blob) return blob;
  /* ... for commands expecting binary input and returning binary output */
  function exec_BLOB(p_command in varchar2, p_stdin in clob) return blob;
  /* ... for commands expecting text input and returning binary output */

  /* the following two functions execute just the command "p_command"; no
   * content is piped into the standard input. */ 
  function exec_CLOB(p_command in varchar2) return Clob;
  /* ... for commands returning text output */
  function exec_BLOB(p_command in varchar2) return blob;
  /* ... for commands returning binary output */

  function exec(p_command in varchar2, p_stdin in blob) return number;
  function exec(p_command in varchar2, p_stdin in clob) return number;
  function exec(p_command in varchar2) return number;

  function exec(p_command in varchar2, p_stdin in clob, p_stdout in clob) return number;
  function exec(p_command in varchar2, p_stdin in clob, p_stdout in blob) return number;
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in blob) return number;
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in clob) return number;
  function exec(p_command in varchar2, p_stdout in clob) return number;
  function exec(p_command in varchar2, p_stdout in blob) return number;

  function exec(p_command in varchar2, p_stdin in clob, p_stdout in clob, p_stderr in clob) return number;
  function exec(p_command in varchar2, p_stdin in clob, p_stdout in blob, p_stderr in blob) return number;
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in blob, p_stderr in blob) return number;
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in clob, p_stderr in clob) return number;
  function exec(p_command in varchar2, p_stdout in clob, p_stderr in clob) return number;
  function exec(p_command in varchar2, p_stdout in blob, p_stderr in blob) return number;



end os_command;
/
sho err

prompt ... package spec LOB_WRITER_PLSQL (deprecated)

create or replace package lob_writer_plsql is
  procedure write_clob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      clob
  ); 
  procedure write_blob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      blob
  ); 
end lob_writer_plsql;
/
sho err

prompt ... package spec FILE_SECURITY

create or replace package file_security authid current_user is
  READ  constant pls_integer := 1;
  WRITE constant pls_integer := 2;
  EXEC  constant pls_integer := 4;
 
  procedure grant_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer  
  );

  procedure revoke_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer  
  );
  
  procedure restrict_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer 
  );

  procedure grant_stdin_stdout(
    p_grantee    in varchar2
  ); 

  function get_script_grant_java_privs(
    p_directory in varchar2, 
    p_grantee in varchar2 default null
  ) return varchar2;
end file_security;
/
sho err

prompt ... package spec FILE_PKG_VERSION

create or replace package file_pkg_version is
  pkg_version varchar2(200) := '1.0';
  function get_version return varchar2;
end file_pkg_version;
/
sho err

