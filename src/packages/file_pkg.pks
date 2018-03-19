create or replace package file_pkg authid current_user
is
  pkg_version varchar2(100) := '1.0RC1';
  procedure set_batch_size (p_batch_size in number default 10);
  function get_batch_size return number;
  function get_file( p_file_path in varchar2) return file_type;
  function get_file_list( p_directory in file_type) return file_list_type;
  function get_recursive_file_list(p_directory in file_type) return file_list_type;
  function get_path_separator return varchar2;
  function get_root_directories return file_list_type;
  function get_root_directory return file_type;
  procedure set_fs_encoding(p_fs_encoding in varchar2, p_reset_session boolean default true);
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
