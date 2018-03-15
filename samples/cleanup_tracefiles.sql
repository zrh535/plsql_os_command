create or replace package pkg_cleanup is
  procedure cleanup_tracefiles(
    p_until_date in date default null
  );
  procedure cleanup alertlog;
  procedure cleanup_listenertrace;
end pkg_cleanup;
/


create or replace package pkg_cleanup is
  procedure cleanup_tracefiles(
    p_until_date in date default null
  ) is
    l_udump_dir v$parameter.value%TYPE;
  begin
    select value into l_udump_dir from v$parameter
    where lower(name) = 'user_dump_dest';
    for cs_file in (
      select as file_handle 
      from table(file_pkg.get_file_list(file_pkg.get_file(l_udump_dir)))
      where file_name like '%tr_' and (last_modified < p_until_date or p_until_date is null)
    ) loop
     file_handle.delete_file();
    end loop;
  end cleanup_tracefiles;  

  procedure cleanup alertlog is
    l_udump_dir v$parameter.value%TYPE;
  begin
    select value into l_udump_dir from v$parameter
    where lower(name) = 'user_dump_dest';
    
    p_gzip_backup in boolean default true
  );
end pkg_cleanup;
/


