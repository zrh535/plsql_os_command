create or replace package os_command authid current_user is
  pkg_version varchar2(100) := '1.0';
  procedure set_working_dir (p_workdir in file_type);
  procedure clear_working_dir;
  function get_working_dir return FILE_TYPE;

  procedure clear_environment;
  procedure set_env_var(p_env_name in varchar2, p_env_value in varchar2);
  procedure remove_env_var(p_env_name in varchar2);
  function get_env_var(p_env_name in varchar2) return varchar2;
$IF DBMS_DB_VERSION.VERSION >= 11 $THEN
  procedure load_env;
  procedure load_env(p_env_name in varchar2);
$end

  procedure use_custom_env;
  procedure use_default_env;

  procedure set_Shell(p_shell_path in varchar2, p_shell_switch in varchar2);
  function get_shell return varchar2;
  procedure set_exec_in_shell;
  procedure set_exec_direct;

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
