/*
 * 03-plsql-body.sql
 *
 * DATABASE VERSION:
 *    12g Release 1 (12.1.0.x)
 *
 * DESCRIPTION:
 *    PL/SQL Package Bodys
 *    + OS_COMMAND
 *    + FILE_PKG
 *    + LOB_WRITER_PLSQL
 *
 *    See the documentation and README files vor more information
 *
 * AUTHOR:
 *    Carsten Czarski (carsten.czarski@gmx.de)
 *
 * VERSION:
 *    1.0
 */

prompt ... type body FILE_TYPE

create or replace type body file_type as
  member function get_bfile(p_directory_name in varchar2 default null) return bfile is
  l_dirname  varchar2(200);
    l_filename varchar2(4000);
    l_pathsep  varchar2(10) := file_pkg.get_path_separator;
    l_bfile    bfile;
  begin
    if self.is_dir = 'Y' then
      raise_application_error(-20000, 'CANNOT CONVERT DIRECTORY INTO BFILE', true);
    end if;

    l_filename := substr(self.file_path, instr(self.file_path, file_pkg.get_path_separator, -1));
    l_filename := ltrim(l_filename, l_pathsep);

    if p_directory_name is not null then
      l_bfile :=  bfilename(p_directory_name, l_filename);
    else
      l_dirname := self.get_directory();
      if l_dirname is null then
        raise_application_error(-20000, 'NO DIRECTORY OBJECT PRESENT FOR THIS FILE_TYPE', true);
      else
        l_bfile := bfilename(l_dirname, l_filename);
      end if;
    end if;
    return l_bfile;
  end get_bfile;

 member function get_directory return varchar2 is
    l_filename varchar2(4000);
    l_dirpath  varchar2(4000);
    l_dirname  all_directories.directory_path%type;
    l_pathsep  varchar2(10) := file_pkg.get_path_separator;
  begin
    if self.is_dir = 'Y' then
      l_dirpath := rtrim(self.file_path, l_pathsep);
    else
      l_dirpath  := substr(self.file_path, 1, instr(self.file_path, l_pathsep, -1));
      l_dirpath  := file_pkg.remove_multiple_separators(l_dirpath);
      l_filename := substr(self.file_path, instr(self.file_path, l_pathsep, -1));
      l_filename := ltrim(l_filename, l_pathsep);
    end if;
    begin
      if l_dirpath is not null then
        -- Inline View with MATERIALIZE hint to avoid ORA-904 here ... maybe a bug in 12c
        with a as (
          select /*+ MATERIALIZE */ * from all_directories
        ) select directory_name into l_dirname
        from a
        where file_pkg.remove_multiple_separators(directory_path) = l_dirpath;
      else
        -- Inline View with MATERIALIZE hint to avoid ORA-904 here ... maybe a bug in 12c
        with a as (
          select /*+ MATERIALIZE */ * from all_directories
        ) select directory_name into l_dirname
        from a
        where file_pkg.remove_multiple_separators(directory_path) is null;
      end if;
    exception
      when NO_DATA_FOUND then
        raise_application_error(-20000, 'NO DIRECTORY OBJECT PRESENT FOR THIS FILE_TYPE', true);
      when TOO_MANY_ROWS then
        raise_application_error(-20000, 'TOO MANY DIRECTORY OBJECTS MATCH THIS FILE_TYPE', true);
    end;
    return l_dirname;
  end;
end;
/
sho err

prompt ... package body FILE_PKG

create or replace package body file_pkg is
  g_batch_size number := 10;

  procedure set_batch_size (p_batch_size in number default 10) is
  begin
    g_batch_size := p_batch_size;
  end set_batch_size;

  function get_batch_size return number
  is begin
    return g_batch_size;
  end get_batch_size;

  function get_file(
    p_file_path in varchar2
  ) return file_type
  is language java name 'FileType.getFile(java.lang.String) return oracle.sql.STRUCT';

  function get_file_list(
    p_directory in file_type
  ) return file_list_type
  is language java name 'FileType.getFileList(oracle.sql.STRUCT) return oracle.sql.ARRAY';

  function get_recursive_file_list(
    p_directory in file_type
  ) return file_list_type
  is language java name 'FileType.getRecursiveFileList(oracle.sql.STRUCT) return oracle.sql.ARRAY';

  function get_path_separator return varchar2
  is language java name 'FileType.getPathSeparator() return java.lang.String';

  function get_root_directories return file_list_type
  is language java name 'FileType.getRootList() return oracle.sql.ARRAY';

  function get_root_directory return file_type
  is language java name 'FileType.getRoot() return oracle.sql.STRUCT';

  /* 0.9 ## Pipelined Directory Listing */
  procedure prepare_file_list(p_directory in file_type)
  is language java name 'FileType.prepareFileList(oracle.sql.STRUCT)';

  procedure prepare_recursive_file_list(p_directory in file_type)
  is language java name 'FileType.prepareRecursiveFileList(oracle.sql.STRUCT)';

  procedure reset_file_list_cursor
  is language java name 'FileType.resetFileListCursor()';

  function get_file_from_list return file_type
  is language java name 'FileType.readFile() return oracle.sql.STRUCT';

  function get_files_from_list(p_files_count in number) return file_list_type
  is language java name 'FileType.readFiles(int) return oracle.sql.ARRAY';

  procedure do_set_fs_encoding (p_fs_encoding in varchar2)
  is language java name 'FileType.setFsEncoding(java.lang.String)';

  procedure set_fs_encoding(p_fs_encoding in varchar2, p_reset_session boolean default true) is
    v_message varchar2(32767);
  begin
    if p_reset_session then
      v_message := dbms_java.endsession;
    end if;
    do_set_fs_encoding(p_fs_encoding);
  end set_fs_encoding;

  function get_fs_encoding return varchar2
  is language java name 'FileType.getFsEncoding() return java.lang.String';

  function get_recursive_file_list_p (p_directory in file_type)
  return file_list_type pipelined is
    v_current_files file_list_type := null;
  begin
    prepare_recursive_file_list(p_directory);
    loop
      v_current_files := get_files_from_list(g_batch_size);
      if v_current_files is null then
        exit;
      else
        for i in v_current_files.first..v_current_files.last loop
          pipe row (v_current_files(i));
        end loop;
      end if;
    end loop;
    return;
  end get_recursive_file_list_p;

  function get_file_list_p(p_directory in file_type)
  return file_list_type pipelined is
    v_current_files file_list_type := null;
  begin
    prepare_file_list(p_directory);
    loop
      v_current_files := get_files_from_list(g_batch_size);
      if v_current_files is null then
        exit;
      else
        for i in v_current_files.first..v_current_files.last loop
          pipe row (v_current_files(i));
        end loop;
      end if;
    end loop;
    return;
  end get_file_list_p;

  function get_file_list(p_directory_name in varchar2) return file_list_type is
  begin
    return get_file_list(p_directory => get_file(p_directory_name, ''));
  end get_file_list;

  function get_file_list_p(p_directory_name in varchar2)
  return file_list_type pipelined is
    v_current_files file_list_type := null;
  begin
    prepare_file_list(get_file(p_directory_name, ''));
    loop
      v_current_files := get_files_from_list(g_batch_size);
      if v_current_files is null then
        exit;
      else
        for i in v_current_files.first..v_current_files.last loop
          pipe row (v_current_files(i));
        end loop;
      end if;
    end loop;
    return;
  end get_file_list_p;

  function get_file(
    p_directory in varchar2,
    p_filename in varchar2
  ) return file_type is
    l_path all_directories.directory_path%type;
  begin
    begin
      select directory_path into l_path
      from all_directories
      where directory_name = p_directory;
    exception
      when NO_DATA_FOUND then
        raise_application_error (-20000, 'DIRECTORY IS NOT ACCESSIBLE OR DOES NOT EXIST', true);
    end;
    return get_file(l_path || file_pkg.get_path_separator || p_filename);
  end get_file;

  function get_file(p_bfile in bfile) return file_type is
    l_dirname varchar2(200);
    l_filename varchar2(200);
  begin
    dbms_lob.filegetname(
      file_loc => p_bfile,
      dir_alias => l_dirname,
      filename => l_filename
    );
    return get_file(l_dirname, l_filename);
  end get_file;

  function remove_multiple_separators(p_path in varchar2) return varchar2 is
    l_pathsep  varchar2(10) := file_pkg.get_path_separator;
  begin
    return regexp_replace(rtrim(p_path, l_pathsep), '['||l_pathsep||']{2,}', l_pathsep);
  end remove_multiple_separators;
end file_pkg;
/
sho err

prompt ... package body OS_COMMAND

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
sho err

prompt ... package body LOB_WRITER_PLSQL (deprecated)

create or replace package body lob_writer_plsql is
  procedure write_blob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      blob
  ) is
    v_position pls_integer := 0;
    v_amount   pls_integer;

    v_file     utl_file.file_type;
  begin
    v_file := utl_file.fopen(
      location => p_directory,
      filename => p_filename,
      open_mode => 'wb',
      max_linesize => 32000
    );
    while v_position < dbms_lob.getlength(p_data) loop
      v_amount := (dbms_lob.getlength(p_data) ) - v_position;
      if v_amount > 32000 then
        v_amount := 32000;
      end if;
      utl_file.put_raw(
        file    => v_file,
        buffer  => dbms_lob.substr(
          lob_loc => p_data,
          amount  => v_amount,
          offset  => v_position + 1
        ),
        autoflush => false
      );
      v_position := v_position + v_amount;
    end loop;
    utl_file.fflush(
      file => v_file
    );
    utl_file.fclose(
      file => v_file
    );
  end write_blob;

  procedure write_clob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      clob
  ) is
    v_position pls_integer := 0;
    v_amount   pls_integer;

    v_file     utl_file.file_type;
  begin
    v_file := utl_file.fopen(
      location => p_directory,
      filename => p_filename,
      open_mode => 'w',
      max_linesize => 32000
    );
    while v_position < dbms_lob.getlength(p_data) loop
      v_amount := (dbms_lob.getlength(p_data) ) - v_position;
      if v_amount > 32000 then
        v_amount := 32000;
      end if;
      utl_file.put_line(
        file    => v_file,
        buffer  => dbms_lob.substr(
          lob_loc => p_data,
          amount  => v_amount,
          offset  => v_position + 1
        ),
        autoflush => false
      );
      v_position := v_position + v_amount;
    end loop;
    utl_file.fflush(
      file => v_file
    );
    utl_file.fclose(
      file => v_file
    );
  end write_clob;
end lob_writer_plsql;
/
sho err


prompt ... package body FILE_SECURITY

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
sho err

prompt ... package body FILE_PKG_VERSION

create or replace package body file_pkg_version is
  function get_version return varchar2 is
  begin
    return pkg_version;
  end get_version;
end file_pkg_version;
/
sho err
