-- Important for Windows

begin
  os_command.set_exec_in_shell;
end;
/

-- Execute the "ps" command and get the output (STDOUT)  back

set long 20000

select os_command.exec_clob('/bin/ps -ef') from dual
/

-- Execute a command and get the return code back
-- 0: Success
-- Other: failure

select os_command.exec('/bin/mkdir /home/oracle/testdir') from dual
/

-- Execute a command, pass something to STDIN and get STDOUT (here: binary) back

select os_command.exec_blob('/bin/gzip -c', 'This text is to be compressed') from dual
/


-- Change the shell

begin
  os_command.set_shell('/bin/ksh', '');
  os_command.set_exec_in_shell;
end;
/

-- set the working directory
-- this example creates an empty file /tmp/myfile

begin
  os_command.set_working_dir(file_pkg.get_file('/tmp'));
end;
/

select os_command.exec('/bin/touch myfile') from dual
/

-- Work with environment variables
-- this example creates an empty file /tmp/myfile_thisfile

begin
  -- Activate execution in a shell -> can use environment variables now
  os_command.set_exec_in_shell;
  -- Set the environment variable
  os_command.set_env_var('MYFILENAME', 'thisfile');
  -- Activate the custom environment variables
  os_command.use_custom_env;
end;
/
  
select os_command.exec('/bin/touch /tmp/myfile_${MYFILENAME}') from dual
/




