set verify off

drop table document_table
/

drop sequence seq_documents
/

create table document_table(
  id number(10),
  file_path varchar2(4000),
  file_name varchar2(4000),
  document clob
)
/

create sequence seq_documents 
/


accept ZIPFILE default '/home/oracle/files.zip' prompt '>> Contents of which ZIP file to be loaded [/home/oracle/files.zip] '

declare
  f  file_type;
  fz file_type;

  r  number;
begin
  -- get a handle for the "tmp" directory
  f:=file_pkg.get_file('/tmp');

  -- create a new temporary directory where the zip archive is being
  -- extracted into ... make the filename unique using TIMESTAMP
  fz := f.create_dir(
    'zipdir_temp_'||user||'_'||to_char(systimestamp, 'YYYYMMDD_HH24MISS.SSSS')
  );

  -- DOIT: 
  -- extract the zipfile; the -qq switch is very important here - otherwise
  -- the OS process will not come back
  r := os_command.exec('unzip -o -qq &ZIPFILE. -d '||fz.file_path);

  -- if the result is 0 (=success) load the contents of the temporary directory
  -- (recursively) with ONE (!) SQL INSERT command
  if r = 0 then 
    insert into document_table (
      select 
        seq_documents.nextval id,
        e.file_path,
        e.file_name,
        file_pkg.get_file(e.file_path).get_content_as_clob('iso-8859-1') content 
      from table(file_pkg.get_recursive_file_list(fz)) e
    ); 
  end if;
  
  -- finally delete the temporary directory and its contents
  fz := fz.delete_recursive();
end;
/
sho err
