create or replace type body file_type as
  member function get_bfile(p_directory_name in varchar2 default null) return bfile is
  l_dirname  varchar2(200);
    l_filename varchar2(4000);
    l_pathsep  varchar2(10) := file_pkg.get_path_separator;
    l_bfile    bfile;
  begin
    if self.is_dir = 'Y' then
      raise_application_error(-20000, 'CANNOT CONVERT DIRECTORY INTO BFILE', true);
    end if;

    l_filename := substr(self.file_path, instr(self.file_path, file_pkg.get_path_separator, -1));
    l_filename := ltrim(l_filename, l_pathsep);

    if p_directory_name is not null then
      l_bfile :=  bfilename(p_directory_name, l_filename);
    else
      l_dirname := self.get_directory();
      if l_dirname is null then
        raise_application_error(-20000, 'NO DIRECTORY OBJECT PRESENT FOR THIS FILE_TYPE', true);
      else
        l_bfile := bfilename(l_dirname, l_filename);
      end if;
    end if;
    return l_bfile;
  end get_bfile;

 member function get_directory return varchar2 is
    l_filename varchar2(4000);
    l_dirpath  varchar2(4000);
    l_dirname  all_directories.directory_path%type;
    l_pathsep  varchar2(10) := file_pkg.get_path_separator;
  begin
    if self.is_dir = 'Y' then
      l_dirpath := rtrim(self.file_path, l_pathsep);
    else
      l_dirpath  := substr(self.file_path, 1, instr(self.file_path, l_pathsep, -1));
      l_dirpath  := file_pkg.remove_multiple_separators(l_dirpath);
      l_filename := substr(self.file_path, instr(self.file_path, l_pathsep, -1));
      l_filename := ltrim(l_filename, l_pathsep);
    end if;
    begin
      if l_dirpath is not null then
        -- Inline View with MATERIALIZE hint to avoid ORA-904 here ... maybe a bug in 12c
        with a as (
          select /*+ MATERIALIZE */ * from all_directories
        ) select directory_name into l_dirname
        from a
        where file_pkg.remove_multiple_separators(directory_path) = l_dirpath;
      else
        -- Inline View with MATERIALIZE hint to avoid ORA-904 here ... maybe a bug in 12c
        with a as (
          select /*+ MATERIALIZE */ * from all_directories
        ) select directory_name into l_dirname
        from a
        where file_pkg.remove_multiple_separators(directory_path) is null;
      end if;
    exception
      when NO_DATA_FOUND then
        raise_application_error(-20000, 'NO DIRECTORY OBJECT PRESENT FOR THIS FILE_TYPE', true);
      when TOO_MANY_ROWS then
        raise_application_error(-20000, 'TOO MANY DIRECTORY OBJECTS MATCH THIS FILE_TYPE', true);
    end;
    return l_dirname;
  end;
end;
/
