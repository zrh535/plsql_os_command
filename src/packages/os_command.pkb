create or replace package body os_command is
  procedure set_working_dir (p_workdir in file_type)
  is language java name 'ExternalCall.setWorkingDir(oracle.sql.STRUCT)';
  procedure clear_working_dir
  is language java name 'ExternalCall.clearWorkingDir()';
  function get_working_dir return FILE_TYPE
  is language java name 'ExternalCall.getWorkingDir() return oracle.sql.STRUCT';


  procedure clear_environment
  is language java name 'ExternalCall.clearEnv()';
  procedure set_env_var(p_env_name in varchar2, p_env_value in varchar2)
  is language java name 'ExternalCall.addEnvVar(java.lang.String, java.lang.String)';

  procedure remove_env_var(p_env_name in varchar2)
  is language java name 'ExternalCall.removeEnvVar(java.lang.String)';
  function get_env_var(p_env_name in varchar2) return varchar2
  is language java name 'ExternalCall.getEnvVar(java.lang.String) return java.lang.String';
$IF DBMS_DB_VERSION.VERSION >= 11 $THEN
  procedure load_env
  is language java name 'ExternalCall.loadEnv()';
  procedure load_env(p_env_name in varchar2)
  is language java name 'ExternalCall.loadEnv(java.lang.String)';
$END

  procedure use_custom_env
  is language java name 'ExternalCall.activateEnv()';
  procedure use_default_env
  is language java name 'ExternalCall.deactivateEnv()';


  procedure set_Shell(p_shell_path in varchar2, p_shell_switch in varchar2)
  is language java name 'ExternalCall.setShell(java.lang.String, java.lang.String)';

  function get_shell return varchar2
  is language java name 'ExternalCall.getShell() return java.lang.String';

  procedure set_exec_in_shell
  is language java name 'ExternalCall.useShell()';

  procedure set_exec_direct
  is language java name 'ExternalCall.useNoShell()';



  function exec_CLOB(p_command in varchar2, p_stdin in blob) return clob
  is language java name 'ExternalCall.execClob(java.lang.String, oracle.sql.BLOB) return oracle.sql.CLOB';

  function exec_CLOB(p_command in varchar2, p_stdin in clob) return clob
  is language java name 'ExternalCall.execClob(java.lang.String, oracle.sql.CLOB) return oracle.sql.CLOB';

  function exec_BLOB(p_command in varchar2, p_stdin in blob) return blob
  is language java name 'ExternalCall.execBlob(java.lang.String, oracle.sql.BLOB) return oracle.sql.BLOB';

  function exec_BLOB(p_command in varchar2, p_stdin in clob) return blob
  is language java name 'ExternalCall.execBlob(java.lang.String, oracle.sql.CLOB) return oracle.sql.BLOB';

  function exec_CLOB(p_command in varchar2) return Clob
  is language java name 'ExternalCall.execClob(java.lang.String) return oracle.sql.CLOB';

  function exec_BLOB(p_command in varchar2) return blob
  is language java name 'ExternalCall.execBlob(java.lang.String) return oracle.sql.BLOB';

  function exec(p_command in varchar2, p_stdin in blob) return number
  is language java name 'ExternalCall.exec(java.lang.String, oracle.sql.BLOB) return int';

  function exec(p_command in varchar2, p_stdin in clob) return number
  is language java name 'ExternalCall.exec(java.lang.String, oracle.sql.CLOB) return int';

  function exec(p_command in varchar2) return number
  is language java name 'ExternalCall.exec(java.lang.String) return int';

  function exec(p_command in varchar2, p_stdin in clob, p_stdout in clob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.CLOB, oracle.sql.CLOB) return int';

  function exec(p_command in varchar2, p_stdin in clob, p_stdout in blob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.CLOB, oracle.sql.BLOB) return int';

  function exec(p_command in varchar2, p_stdin in blob, p_stdout in blob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.BLOB, oracle.sql.BLOB) return int';

  function exec(p_command in varchar2, p_stdin in blob, p_stdout in clob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.BLOB, oracle.sql.CLOB) return int';

  function exec(p_command in varchar2, p_stdout in clob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.CLOB) return int';

  function exec(p_command in varchar2, p_stdout in blob) return number
  is language java name 'ExternalCall.execOut(java.lang.String, oracle.sql.BLOB) return int';


  function exec(p_command in varchar2, p_stdin in clob, p_stdout in clob, p_stderr in clob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.CLOB, oracle.sql.CLOB, oracle.sql.CLOB) return int';
  function exec(p_command in varchar2, p_stdin in clob, p_stdout in blob, p_stderr in blob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.CLOB, oracle.sql.BLOB, oracle.sql.BLOB) return int';
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in blob, p_stderr in blob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.BLOB, oracle.sql.BLOB, oracle.sql.BLOB) return int';
  function exec(p_command in varchar2, p_stdin in blob, p_stdout in clob, p_stderr in clob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.BLOB, oracle.sql.CLOB, oracle.sql.CLOB) return int';
  function exec(p_command in varchar2, p_stdout in clob, p_stderr in clob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.CLOB, oracle.sql.CLOB) return int';
  function exec(p_command in varchar2, p_stdout in blob, p_stderr in blob) return number
  is language java name 'ExternalCall.execOutErr(java.lang.String, oracle.sql.BLOB, oracle.sql.BLOB) return int';
end os_command;
/
