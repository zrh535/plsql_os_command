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
