create or replace and resolve java source named "FILE_TYPE_JAVA" as
import java.io.*;
import oracle.jdbc.*;
import oracle.jdbc2.*;
import oracle.sql.*;
import java.sql.*;
import java.util.*;
import java.math.*;


public class FileType implements SQLData {

  private String             filePath;
  private String             sqlType;

  /* ## 0.9: File Input Streaming */
  private static Hashtable hsFileStream = new Hashtable();
  private static String sFsEncoding = null;

  private static Connection con;
  private static ArrayDescriptor aDescr;
  private static StructDescriptor sDescr;

  private static Object[] oFileType = new Object[8];
  private static File[]   oFileList = null;

  static {
    try {
      con = DriverManager.getConnection("jdbc:default:connection:");
      aDescr = ArrayDescriptor.createDescriptor(getFileTypeOwner(con)+".FILE_LIST_TYPE", con);
      sDescr = StructDescriptor.createDescriptor(FileType.getFileTypeOwner(con)+".FILE_TYPE", con);
    } catch (Exception e) {
      e.printStackTrace(System.out);
    }
  }

  public static void setFsEncoding(String psEncoding) {
    System.setProperty("file.encoding", psEncoding);
  }

  public static String getFsEncoding() {
    return System.getProperty("file.encoding");
  }


  public void openInputStream() throws Exception {
    if (!hasInputStream()) {
      FileInputStream fis = new FileInputStream(filePath);
      hsFileStream.put(filePath, fis);
    } else {
      throw new Exception ("FILE STREAM ALREADY OPEN");
    }
  }

  public void closeInputStream() throws Exception {
    if (hasInputStream()) {
      ((FileInputStream)hsFileStream.get(filePath)).close();
      hsFileStream.remove(filePath);
    } else {
      throw new Exception ("FILE STREAM NOT OPEN");
    }
  }

  private boolean hasInputStream() throws Exception {
    return (hsFileStream.containsKey(filePath));
  }

  public int isStreamOpen() throws Exception {
    return (hasInputStream()?1:0);
  }

  public void skipBytes(long pAmount) throws Exception {
    if (hasInputStream()) {
      ((FileInputStream)hsFileStream.get(filePath)).skip(pAmount);
      hsFileStream.remove(filePath);
    } else {
      throw new Exception ("FILE STREAM NOT OPEN");
    }
  }

  public Integer readByte() throws Exception {
    int iByteRead;
    if (hasInputStream()) {
      iByteRead = ((FileInputStream)hsFileStream.get(filePath)).read();
    } else {
      throw new Exception ("FILE STREAM IS NOT OPEN");
    }
    if (iByteRead == -1) {
      return null;
    } else {
      return new Integer(iByteRead);
    }
  }

  public long writeBytes(byte[] baBytes, long pOffset) throws Exception {
    long iLength = 0;
    RandomAccessFile fi = new RandomAccessFile(new File(filePath), "rw");
    fi.seek(pOffset);
    fi.write(baBytes);
    fi.close();
    return new File(filePath).length();
  }

  public long writeString(String sString, long pOffset, String pCharset) throws Exception {
    return writeBytes(sString.getBytes(pCharset), pOffset);
  }

  public byte[] readBytes(int pAmount, long pOffset) throws Exception {
    int    iBytesRead = 0;
    byte[] baBytesRead;
    byte[] baBytesReturn;

    if (pAmount <= 32767) {
      baBytesRead = new byte[pAmount + 1];
      RandomAccessFile fi = new RandomAccessFile(new File(filePath), "r");
      fi.seek(pOffset);
      iBytesRead = fi.read(baBytesRead, 0, pAmount);
      fi.close();
    } else {
      throw new Exception ("THIS METHOD CANNOT READ MORE THAN 32767 BYTES");
    }
    if (iBytesRead != -1) {
      baBytesReturn = new byte[iBytesRead];
      System.arraycopy(baBytesRead, 0, baBytesReturn, 0, iBytesRead);
    } else {
      baBytesReturn = null;
    }
    return baBytesReturn;
  }

  public String readString(int pAmount, long pOffset, String pCharset) throws Exception {
    byte[] baBytes = readBytes(pAmount, pOffset);
    if (baBytes == null) {
      return null;
    } else {
      return new String(baBytes, pCharset);
    }
  }

  public byte[] readBytes(int pAmount) throws Exception {
    int    iBytesRead = 0;
    byte[] baBytesRead;
    byte[] baBytesReturn;

    if (hasInputStream()) {
      if (pAmount <= 32767) {
        baBytesRead = new byte[pAmount];
        iBytesRead = ((FileInputStream)hsFileStream.get(filePath)).read(baBytesRead);
      } else {
        throw new Exception ("THIS METHOD CANNOT READ MORE THAN 32767 BYTES");
      }
    } else {
      throw new Exception ("FILE STREAM IS NOT OPEN");
    }
    if (iBytesRead != -1) {
      baBytesReturn = new byte[iBytesRead];
      System.arraycopy(baBytesRead, 0, baBytesReturn, 0, iBytesRead);
    } else {
      baBytesReturn = null;
    }
    return baBytesReturn;
  }

  public String readString(int pAmount, String pCharset) throws Exception {
    byte[] baBytes = readBytes(pAmount);
    if (baBytes == null) {
      return null;
    } else {
      return new String(baBytes, pCharset);
    }
  }

  /* ## 0.9: Pipelined Directory Listing */

  private static Vector vLastDirListing = new Vector();
  private static int    iDirListCursor = 0;
  private static Vector vTransportFiles = new Vector();

  private static void prepareFileList(String pDir, boolean pRecursive) throws Exception {
    vLastDirListing.clear();
    iDirListCursor = 0;
    doPrepareFileList(pDir, pRecursive);
  }

  private static void doPrepareFileList(String pDir, boolean pRecursive) throws Exception {
    File[] oFileList = new File(pDir).listFiles();

    if (oFileList != null) {
      for (int i=0;i<oFileList.length;i++) {
        vLastDirListing.add(oFileList[i]);
        try {
          if (oFileList[i].isDirectory() && pRecursive) {
            doPrepareFileList(oFileList[i].getAbsolutePath(), true);
          }
        } catch (java.security.AccessControlException e) {
        }
      }
    }
  }

  public static void prepareFileList(oracle.sql.STRUCT pFile) throws Exception{
    Object[] oInputAttrs = pFile.getAttributes();
    prepareFileList((String)oInputAttrs[0], false);
  }

  public static void prepareRecursiveFileList(oracle.sql.STRUCT pFile) throws Exception{
    Object[] oInputAttrs = pFile.getAttributes();
    prepareFileList((String)oInputAttrs[0], true);
  }


  public static void resetFileListCursor() {
    iDirListCursor = 0;
  }

  public static STRUCT readFile() throws Exception {
    if (vLastDirListing == null) {
      throw new Exception("NO DIRECTORY LISTING AVAILABLE - CALL PREPAREFILELIST FIRST");
    }
    if (iDirListCursor < vLastDirListing.size()) {
      iDirListCursor ++;
      return convertToStruct((File)vLastDirListing.get(iDirListCursor - 1));
    } else {
      return null;
    }
  }

  public static ARRAY readFiles(int pFileCount) throws Exception {
    if (vLastDirListing == null) {
      throw new Exception("NO DIRECTORY LISTING AVAILABLE - CALL PREPAREFILELIST FIRST");
    }

    if (iDirListCursor < vLastDirListing.size()) {
      int      iCurrentFileCnt = 0;
      vTransportFiles.setSize(0);

      while (iDirListCursor < vLastDirListing.size() && iCurrentFileCnt < pFileCount) {
        vTransportFiles.add(convertToStruct((File)vLastDirListing.get(iDirListCursor)));
        iDirListCursor++;
        iCurrentFileCnt++;
      }
      return new ARRAY(aDescr, con, vTransportFiles.toArray());
    } else {
      return null;
    }
  }

  public static String getFileTypeOwner(Connection con) throws Exception {
    String sFileTypeOwner = null;
    CallableStatement stmt = con.prepareCall("begin dbms_utility.name_resolve(?,?,?,?,?,?,?,?); end;");
    stmt.setString(1, "FILE_TYPE");
    stmt.setInt(2, 7);
    stmt.registerOutParameter(3, java.sql.Types.VARCHAR);
    stmt.registerOutParameter(4, java.sql.Types.VARCHAR);
    stmt.registerOutParameter(5, java.sql.Types.VARCHAR);
    stmt.registerOutParameter(6, java.sql.Types.VARCHAR);
    stmt.registerOutParameter(7, oracle.jdbc.OracleTypes.NUMBER);
    stmt.registerOutParameter(8, oracle.jdbc.OracleTypes.NUMBER);
    stmt.execute();
    sFileTypeOwner = stmt.getString(3);
    stmt.close();
    return sFileTypeOwner;
  }

  public static String getPathSeparator() {
    return File.separator;
  }


  public static ARRAY getRootList() throws Exception{
    oFileList = File.listRoots();
    STRUCT[] oRoots = new STRUCT[oFileList.length];
    for (int i=0;i<oRoots.length;i++) {
      oRoots[i] = convertToStruct(oFileList[i]);
    }
    return new ARRAY(aDescr, con, oRoots);
  }

  public static STRUCT getRoot() throws Exception {
    return convertToStruct(File.listRoots()[0]);
  }

  public static ARRAY getFileList(oracle.sql.STRUCT pFile, boolean pRecursive) throws Exception{
    Object[] oInputAttrs = pFile.getAttributes();

    vTransportFiles.setSize(0);
    getFileList((String)oInputAttrs[0], vTransportFiles, pRecursive);
    return new ARRAY(aDescr, con, vTransportFiles.toArray());
  }

  public static ARRAY getFileList(oracle.sql.STRUCT pFile) throws Exception{
    return getFileList(pFile, false);
  }

  public static ARRAY getRecursiveFileList(oracle.sql.STRUCT pFile) throws Exception{
    return getFileList(pFile, true);
  }

  private static void getFileList(String pDir, Vector oraFileEntries, boolean pRecursive) throws Exception {
    File[] oFileList = new File(pDir).listFiles();
    if (oFileList != null) {
      for (int i=0;i<oFileList.length;i++) {
        oraFileEntries.add(convertToStruct(oFileList[i]));
        try {
          if (oFileList[i].isDirectory() && pRecursive) {
            getFileList(oFileList[i].getAbsolutePath(), oraFileEntries, true);
          }
        } catch (java.security.AccessControlException e) {
        }
      }
    }
  }



  public static STRUCT getFile(String pFilePath) throws Exception {
    File f = new File(pFilePath);
    return convertToStruct(f);
  }

  private static STRUCT convertToStruct(File f) throws Exception {
    STRUCT   oraFileType = null;

    oFileType[0] = f.getAbsolutePath();
    try {
      if (f.exists()) {
        oFileType[1] = f.getName();
        oFileType[2] = new BigDecimal(f.length());
        oFileType[3] = new java.sql.Timestamp(f.lastModified());
        oFileType[4] = (f.isDirectory()?"Y":"N");
        try {
          oFileType[5] = (f.canWrite()?"Y":"N");
        } catch (SecurityException e) {
          oFileType[5] = "N";
        }
        oFileType[6] = (f.canRead()?"Y":"N");
        oFileType[7] = "Y";
      } else {
        oFileType[1] = null;
        oFileType[2] = null;
        oFileType[3] = null;
        oFileType[4] = null;
        oFileType[5] = null;
        oFileType[6] = null;
        oFileType[7] = "N";
      }
    } catch (java.security.AccessControlException e) {
        oFileType[1] = null;
        oFileType[2] = null;
        oFileType[3] = null;
        oFileType[4] = null;
        oFileType[5] = null;
        oFileType[6] = "N";
        oFileType[7] = null;
    }
    oraFileType = new STRUCT(sDescr, con, oFileType);
    return oraFileType;
  }

  private static File convertToFile(STRUCT s) throws Exception {
    File f = new File((String)s.getAttributes()[0]);
    return f;
  }

  public STRUCT createEmptyFile() throws Exception {
    File f = new File(filePath);
    if (f.createNewFile()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }

  public STRUCT mkdirs() throws Exception {
    File f = new File(filePath);
    if (f.mkdirs()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }

  public STRUCT mkdir() throws Exception {
    File f = new File(filePath);
    if (f.mkdir()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }

  public STRUCT getParent() throws Exception {
    File cf = new File(filePath);
    File pf = cf.getParentFile();
    if (pf == null) {
      return convertToStruct(cf);
    } else {
      return convertToStruct(pf);
    }
  }

  public STRUCT mkdir(String sDirName) throws Exception {
    File f = new File(filePath + File.separator + sDirName);
    if (f.mkdir()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }

  public STRUCT createFile (String sFileName) throws Exception {
    File f = new File(filePath + File.separator + sFileName);
    if (f.createNewFile()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }

  public STRUCT renameTo(STRUCT newFile) throws Exception {
    File sf = new File(filePath);
    File tf = FileType.convertToFile(newFile);
    if ( sf.renameTo(tf)) {
      return FileType.convertToStruct(tf);
    } else {
      return null;
    }
  }

  public STRUCT delete() throws Exception {
    File f = new File(filePath);
    if (f.delete()) {
      return FileType.convertToStruct(f);
    } else {
      return null;
    }
  }



  public void copy(InputStream r, OutputStream w, byte[] b) throws Exception {
    int iCharsRead = 0;

    while ((iCharsRead = r.read(b, 0, b.length)) != -1) {
      w.write(b, 0, iCharsRead);
    }
  }

  public void copyConvert(InputStream r, Writer w, byte[] b, String sCharset) throws Exception {
    int iCharsRead = 0;
    while ((iCharsRead = r.read(b, 0, b.length)) != -1) {
      w.write(new String(b, sCharset).toCharArray(), 0, iCharsRead);
    }
  }

  public void copy(Reader r, Writer w, char[] b) throws Exception {
    int iCharsRead = 0;

    while ((iCharsRead = r.read(b, 0, b.length)) != -1) {
      w.write(b, 0, iCharsRead);
    }
  }

  public long writeClobToFile(CLOB clobContent) throws Exception {
    return writeClobToFile(clobContent, false);
  }

  public long appendClobToFile(CLOB clobContent) throws Exception {
    return writeClobToFile(clobContent, true);
  }

  public long writeBlobToFile(BLOB blobContent) throws Exception {
    return writeBlobToFile(blobContent, false);
  }

  public long appendBlobToFile(BLOB blobContent) throws Exception {
    return writeBlobToFile(blobContent, true);
  }


  public long appendStringToFile(String text) throws Exception {
    File f = new File(filePath);
    Writer fileWriter  = null;
    fileWriter = new FileWriter(f, true);
    fileWriter.write(text, 0, text.length());
    fileWriter.flush();
    fileWriter.close();
    return f.length();
  }

  public STRUCT copy(STRUCT targetFile) throws Exception {
    return copy(targetFile, 65536);
  }

  public STRUCT copy(STRUCT targetFile, int buffer) throws Exception {
    File tf = FileType.convertToFile(targetFile);
    File sf = new File(filePath);
    byte[] b = new byte[buffer];
    FileInputStream is = new FileInputStream(sf);
    FileOutputStream os = new FileOutputStream(tf);
    copy(is, os, b);
    is.close();
    os.close();
    return FileType.convertToStruct(tf);
  }

  public long writeClobToFile(CLOB clobContent, boolean append) throws Exception {
    File f = new File(filePath);
    Reader              clobReader  = null;
    Writer              fileWriter  = null;

    char[] cBuffer = null;

    clobReader = clobContent.getCharacterStream(0L);
    cBuffer = new char[clobContent.getChunkSize()];
    fileWriter = new FileWriter(f, append);

    copy(clobReader, fileWriter, cBuffer);

    clobReader.close();
    fileWriter.flush();
    fileWriter.close();
    return f.length();
  }

  public long writeBlobToFile(BLOB blobContent, boolean append) throws Exception {
    File f = new File(filePath);
    InputStream         blobReader  = null;
    OutputStream        fileWriter  = null;

    byte[] bBuffer = null;

    blobContent.open(BLOB.MODE_READONLY);
    blobReader = blobContent.getBinaryStream(0L);
    bBuffer = new byte[blobContent.getChunkSize()];
    fileWriter = new FileOutputStream(f, append);

    copy(blobReader, fileWriter, bBuffer);

    blobReader.close();
    fileWriter.flush();
    fileWriter.close();
    blobContent.close();
    return f.length();
  }

  public CLOB getContentCLOB(String pCharset) throws Exception {
    File f = new File(filePath);
    Writer              clobWriter  = null;
    InputStream         fileReader  = null;

    byte[] bBuffer = null;

    CLOB fileContent = CLOB.createTemporary(con, true, CLOB.DURATION_CALL);
    bBuffer = new byte[fileContent.getChunkSize()];

    clobWriter = fileContent.getCharacterOutputStream(0L);
    try {
      fileReader = new FileInputStream(f);
      copyConvert(fileReader, clobWriter, bBuffer, pCharset);
      fileReader.close();
      clobWriter.flush();
      clobWriter.close();
    } catch (Exception e) {
      clobWriter.flush();
      clobWriter.close();
      fileContent = null;
    } finally {
      if (fileReader != null) {
       fileReader.close();
      }
    }
    return fileContent;
  }

  public long getFreeSpace() throws Exception {
    return new File(filePath).getFreeSpace();
  }

  public BLOB getContentBLOB() throws Exception {
    File f = new File(filePath);
    InputStream  fileReader = null;
    OutputStream blobWriter = null;

    byte[] bBuffer = null;

    BLOB fileContent = BLOB.createTemporary(con, true, BLOB.DURATION_CALL);
    bBuffer = new byte[fileContent.getChunkSize()];

    blobWriter = fileContent.getBinaryOutputStream(0L);
    try {
      fileReader = new FileInputStream(f);
      copy(fileReader, blobWriter, bBuffer);
      fileReader.close();
      blobWriter.flush();
      blobWriter.close();
    } catch (Exception e) {
      blobWriter.flush();
      blobWriter.close();
      fileContent = null;
    } finally {
      if (fileReader != null) {
       fileReader.close();
      }
    }
    return fileContent;
  }

  private void deleteRecursive(File currentDir) throws Exception {
    File[] dirEntries = currentDir.listFiles();
    if (dirEntries != null) {
      for (int i=0;i<dirEntries.length;i++) {
        if (dirEntries[i].isDirectory()) {
          deleteRecursive(dirEntries[i]);
          dirEntries[i].delete();
        } else {
          dirEntries[i].delete();
        }
      }
    }
    currentDir.delete();
  }

  public STRUCT deleteRecursive() throws Exception {
    File f = new File(filePath);
    deleteRecursive(f);
    return FileType.convertToStruct(f);
  }

  public String getSQLTypeName() throws SQLException {
    return sqlType;
  }


  public void readSQL(SQLInput stream, String typeName) throws SQLException
  {
    sqlType = typeName;

    filePath = stream.readString();
    stream.readString();
    stream.readBigDecimal();
    stream.readTimestamp();
    stream.readString();
    stream.readString();
    stream.readString();
    stream.readString();
  }

  public void writeSQL(SQLOutput stream) throws SQLException
  {
    stream.writeString(filePath);
    File f = new File(filePath);
    if (!f.exists()) {
      stream.writeObject(null);
      stream.writeObject(null);
      stream.writeObject(null);
      stream.writeObject(null);
      stream.writeObject(null);
      stream.writeObject(null);
      stream.writeString("N");
    } else {
      stream.writeString(f.getName());
      stream.writeBigDecimal(new BigDecimal(f.length()));
      stream.writeTimestamp(new java.sql.Timestamp(f.lastModified()));
      stream.writeString(f.isDirectory()?"Y":"N");
      try {
        stream.writeString(f.canWrite()?"Y":"N");
      } catch (SecurityException e) {
        stream.writeString("N");
      }
      stream.writeString(f.canRead()?"Y":"N");
      stream.writeString("Y");
    }
  }
}
/
