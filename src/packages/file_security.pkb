create or replace package body file_security is
  function translate_privs(p_permission in pls_integer) return varchar2 is
    v_privs varchar2(4000);
  begin
    if bitand(p_permission, READ) = READ  then
      v_privs := 'read,';
    end if;
    if bitand(p_permission, WRITE) = WRITE then
      v_privs := v_privs || 'write,';
    end if;
    if bitand(p_permission, EXEC) = EXEC then
      v_privs := v_privs || 'execute,';
    end if;
    v_privs := substr(v_privs, 1, length(v_privs) - 1);
    return v_privs;
  end translate_privs;

  procedure grant_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer
  ) is
  begin
    dbms_java.grant_permission(
      grantee => p_grantee,
      permission_type => 'SYS:java.io.FilePermission',
      permission_name => p_file_path,
      permission_action => translate_privs(p_permission)
    );
  end grant_permission;

  procedure revoke_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer
  ) is
  begin
    dbms_java.revoke_permission(
      grantee => p_grantee,
      permission_type => 'SYS:java.io.FilePermission',
      permission_name => p_file_path,
      permission_action => translate_privs(p_permission)
    );
  end revoke_permission;

  procedure restrict_permission(
    p_file_path  in varchar2,
    p_grantee    in varchar2,
    p_permission in pls_integer
  ) is
  begin
    dbms_java.restrict_permission(
      grantee => p_grantee,
      permission_type => 'SYS:java.io.FilePermission',
      permission_name => p_file_path,
      permission_action => translate_privs(p_permission)
    );
  end restrict_permission;

  procedure grant_stdin_stdout(
    p_grantee    in varchar2
  ) is
  begin
    -- this grants read privilege on STDIN
    dbms_java.grant_permission(
      grantee =>           p_grantee,
      permission_type =>   'SYS:java.lang.RuntimePermission',
      permission_name =>   'readFileDescriptor',
      permission_action => null
    );
    -- this grants write permission on STDOUT
    dbms_java.grant_permission(
      grantee =>           p_grantee,
      permission_type =>   'SYS:java.lang.RuntimePermission',
      permission_name =>   'writeFileDescriptor',
      permission_action => null
    );
  end grant_stdin_stdout;

  function get_script_grant_java_privs(
    p_directory in varchar2,
    p_grantee in varchar2 default null
  ) return varchar2 is
    l_sql_grant_t varchar2(1000) :=
'  dbms_java.grant_permission(
    grantee           => ''##GRANTEE##'',
    permission_type   => ''SYS:java.io.FilePermission'',
    permission_name   => ''##DIR_PATH##'',
    permission_action => ''##ACTION##''
  );';
    l_sql_grant     varchar2(4000);
    l_sql_grant_all varchar2(4000);

    l_dir_privs varchar2(200) := '';
    l_dir_path  varchar2(4000);
  begin
    begin
      select directory_path into l_dir_path
      from all_directories
      where directory_name = p_directory;
    exception
      when NO_DATA_FOUND then
        raise_application_error(-20000, 'DIRECTORY DOES NOT EXIST', true);
    end;

    l_sql_grant_all := 'begin'||chr(10)||chr(10);
    for u in (
      select distinct grantee
      from all_tab_privs tp, all_directories ad
      where tp.table_name = ad.directory_name
      and  tp.table_name = p_directory and (tp.grantee = p_grantee or p_grantee is null)
    ) loop
      l_dir_privs := '';
      l_sql_grant := l_sql_grant_t;
      for g in (
        select privilege
        from all_tab_privs tp, all_directories ad
        where tp.table_name = ad.directory_name and tp.table_schema='SYS' and
              tp.table_name = p_directory and tp.grantee = u.grantee
      ) loop
        l_dir_privs := l_dir_privs || lower(g.privilege) || ',';
      end loop;
      l_dir_privs := rtrim(l_dir_privs, ',');
      l_sql_grant := replace(l_sql_grant, '##GRANTEE##', upper(u.grantee));
      l_sql_grant := replace(l_sql_grant, '##DIR_PATH##', l_dir_path || file_pkg.get_path_separator || '*');
      l_sql_grant := replace(l_sql_grant, '##ACTION##', lower(l_dir_privs));
      l_sql_grant_all := l_sql_grant_all||l_sql_grant||chr(10)||chr(10);
    end loop;
    l_sql_grant_all := l_sql_grant_all||'end;';
    return l_sql_grant_all;
  end get_script_grant_java_privs;
end file_security;
/
