create or replace package file_pkg_version is
  pkg_version varchar2(200) := '1.0';
  function get_version return varchar2;
end file_pkg_version;
/
