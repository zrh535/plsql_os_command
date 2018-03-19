create or replace package lob_writer_plsql is
  procedure write_clob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      clob
  );
  procedure write_blob(
    p_directory varchar2,
    p_filename  varchar2,
    p_data      blob
  );
end lob_writer_plsql;
/
