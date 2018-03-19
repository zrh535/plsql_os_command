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
