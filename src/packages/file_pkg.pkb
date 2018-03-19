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
