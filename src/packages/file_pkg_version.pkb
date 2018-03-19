create or replace package body file_pkg_version is
  function get_version return varchar2 is
  begin
    return pkg_version;
  end get_version;
end file_pkg_version;
/
