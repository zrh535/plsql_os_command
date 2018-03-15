-- Get a file handle

select file_pkg.get_file('/') from dual
/

-- Get a Directory Listing as TABLE OF FILE_TYPE
select l.file_name, l.is_dir, l.file_size
from table(file_pkg.get_file_list(file_pkg.get_file('/'))) l
/

-- Get a directory listing as TABLE OF BFILE

select value(l).get_bfile('MYDIR_OBJECT')
from table(file_pkg.get_file_list(file_pkg.get_file('/'))) l
where l.is_dir='N'
/

-- Get file contents as a BLOB

select file_pkg.get_file('/home/oracle/.bashrc').get_content_as_blob() from dual
/

-- Get file contents as a CLOB 

select file_pkg.get_file('/home/oracle/.bashrc').get_content_as_clob('iso-8859-1') from dual
/

-- Create a table containing all files within a directory

create table tab_files as 
select l.file_name, l.last_modified, value(l).get_content_as_blob() file_content
from table(file_pkg.get_file_list(file_pkg.get_file('/'))) l
where l.is_dir='N'
/

-- Get a handle to a nonexisting file

select file_pkg.get_file('/home/oracle/file-does-not-exist') from dual
/

-- Append Text to a file (if file does not exist, create one)
select file_pkg.get_file('/home/oracle/file-does-not-exist').append_to_file('THIS IS A TEXT') from dual
/
select file_pkg.get_file('/home/oracle/file-does-not-exist').append_to_file(chr(10)) from dual
/
select file_pkg.get_file('/home/oracle/file-does-not-exist').append_to_file('THIS IS ANOTHER TEXT') from dual
/
select file_pkg.get_file('/home/oracle/file-does-not-exist').get_content_as_clob('iso-8859-1') from dual
/

-- Delete a file
select file_pkg.get_file('/home/oracle/file-does-not-exist').delete_file() from dual
/


