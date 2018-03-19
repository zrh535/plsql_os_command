create type FILE_TYPE authid current_user as object
(
  file_path      varchar2(4000),
  file_name      varchar2(4000),
  file_size      number,
  last_modified  date,
  is_dir         char(1),
  is_writeable   char(1),
  is_readable    char(1),
  file_exists    char(1),
  member function move(p_target_file in file_type) return file_type
    is language java name 'FileType.renameTo(oracle.sql.STRUCT) return oracle.sql.STRUCT',
  member function delete_file return file_type
    is language java name 'FileType.delete() return oracle.sql.STRUCT',
  member function delete_recursive return file_type
    is language java name 'FileType.deleteRecursive() return oracle.sql.STRUCT',
  member function make_file return FILE_TYPE
    is language java name 'FileType.createEmptyFile() return oracle.sql.STRUCT',
  member function make_dir return FILE_TYPE
    is language java name 'FileType.mkdir() return int',
  member function create_dir (p_dirname in varchar2) return FILE_TYPE
    is language java name 'FileType.mkdir(java.lang.String) return FileType',
  member function create_file (p_filename in varchar2) return file_type
    is language java name 'FileType.createFile(java.lang.String) return FileType',
  member function copy (p_target_file in file_type) return file_type
    is language java name 'FileType.copy(oracle.sql.STRUCT) return oracle.sql.STRUCT',
  member function make_all_dirs return file_type
    is language java name 'FileType.mkdirs() return oracle.sql.STRUCT',
  member function get_content_as_clob(p_charset in varchar2) return clob
    is language java name 'FileType.getContentCLOB(java.lang.String) return oracle.sql.CLOB',
  member function write_to_file(p_content in clob) return number
    is language java name 'FileType.writeClobToFile(oracle.sql.CLOB) return long',
  member function append_to_file(p_content in clob) return number
    is language java name 'FileType.appendClobToFile(oracle.sql.CLOB) return long',
  member function write_to_file(p_content in blob) return number
    is language java name 'FileType.writeBlobToFile(oracle.sql.BLOB) return long',
  member function append_to_file(p_content in blob) return number
    is language java name 'FileType.appendBlobToFile(oracle.sql.BLOB) return long',
  member function append_to_file(p_content in varchar2) return number
    is language java name 'FileType.appendStringToFile(java.lang.String) return long',
  member function get_content_as_blob return blob
    is language java name 'FileType.getContentBLOB() return oracle.sql.BLOB',
  member function get_parent return file_type
    is language java name 'FileType.getParent() return oracle.sql.STRUCT',
  member procedure open_stream
    is language java name 'FileType.openInputStream()',
  member procedure close_stream
    is language java name 'FileType.closeInputStream()',
  member function is_stream_open return number
    is language java name 'FileType.isStreamOpen() return int',
  member function read_byte return number
    is language java name 'FileType.readByte() return int',
  member function read_bytes(p_amount in number) return raw
    is language java name 'FileType.readBytes(int) return byte[]',
  member function read_string(p_amount in number, p_charset in varchar2) return varchar2
    is language java name 'FileType.readString(int, java.lang.String) return java.lang.String',
  member function read_bytes(p_amount in number, p_position in number) return raw
    is language java name 'FileType.readBytes(int, long) return byte[]',
  member function read_string(p_amount in number, p_position in number, p_charset in varchar2) return varchar2
    is language java name 'FileType.readString(int, long, java.lang.String) return java.lang.String',
  member function write_bytes(p_bytes in raw, p_position in number) return number
    is language java name 'FileType.writeBytes(byte[], long) return long',
  member function write_string(p_string in varchar2, p_position in number, p_charset in varchar2) return number
    is language java name 'FileType.writeString(java.lang.String, long, java.lang.String) return long',
  member procedure skip_bytes(p_amount in number)
    is language java name 'FileType.skipBytes(long)',
  member function get_free_space return number
    is language java name 'FileType.getFreeSpace() return long',
  static function get_file(p_file_path in varchar2) return file_type
    is language java name 'FileType.getFile(java.lang.String) return FileType',
  member function get_bfile(p_directory_name in varchar2 default null) return bfile,
  member function get_directory return varchar2
)
/

create type file_list_type as table of file_type
/
