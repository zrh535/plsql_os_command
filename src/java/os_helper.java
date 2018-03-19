create or replace and resolve java source named "OS_HELPER" as
import java.io.*;
import oracle.jdbc.*;
import oracle.sql.*;
import java.sql.*;
import java.util.*;
import java.math.*;

public class ExternalCall {
  private static class StreamReaderAccumulator extends Thread {
  	 private final InputStreamReader is;
    private final Writer w;

  	 private Throwable throwable = null;
    char cBuf[] = new char[4096];
    int iCharsRead = 0;

  	 StreamReaderAccumulator (InputStream is, Writer w) {
  	   this.is = new InputStreamReader(is);
      this.w = w;
  	 }

  	 public void run() {
  	   try {
        while ((iCharsRead = is.read(cBuf, 0, cBuf.length)) != -1) {
          w.write(cBuf, 0, iCharsRead);
        }
        is.close();
  	    } catch (Throwable t) {
  		     throwable = t;
  	    }
  	 }
  }

  private static class StreamAccumulator extends Thread {
  	 private final InputStream is;
    private final OutputStream os;

  	 private Throwable throwable = null;
    byte[] cBuf = new byte[4096];
    int iCharsRead = 0;

  	 StreamAccumulator (InputStream is, OutputStream os) {
  	   this.is = is;
      this.os = os;
  	 }

 	 StreamAccumulator (InputStream is) {
  	   this.is = is;
      this.os = null;
  	 }

  	 public void run() {
  	   try {
        while ((iCharsRead = is.read(cBuf, 0, cBuf.length)) != -1) {
          if (os != null) {
            os.write(cBuf, 0, iCharsRead);
          }
        }
        is.close();
  	    } catch (Throwable t) {
  	    }
  	 }
  }

  static class ReturnData {
    public oracle.sql.Datum stdout;
    public oracle.sql.Datum stderr;
    public int              returnCode;
 }

  private static Hashtable vEnvVars = new Hashtable();
  private static File fWorkingDir = null;

  private static boolean useMyEnv = false;

  private static String gsShellPath = null;
  private static String gsShellSwitch = null;
  private static boolean gbUseShell = false;

  private static Connection con;
  private static StructDescriptor sDescr;
  private static Object[] oFileType = new Object[8];

  static {
    if (File.separatorChar == '/') {
      gsShellPath = "/bin/sh";
      gsShellSwitch = "-c";
    } else {
      gsShellPath = "C:\\WINDOWS\\SYSTEM32\\cmd.exe";
      gsShellSwitch = "/C";
    }

    try {
      con = DriverManager.getConnection("jdbc:default:connection:");
      sDescr = StructDescriptor.createDescriptor(FileType.getFileTypeOwner(con)+".FILE_TYPE", con);
    } catch (Exception e) {
      e.printStackTrace(System.out);
    }
  }

  public static void useShell() {
    gbUseShell = true;
  }

  public static void useNoShell() {
    gbUseShell = false;
  }

  public static void setShell(String pShellPath, String pShellSwitch) {
    gsShellPath = pShellPath;
    gsShellSwitch = pShellSwitch;
  }

  public static String getShell() {
    return gsShellPath + " " + gsShellSwitch;
  }

  public static void activateEnv() {
    useMyEnv = true;
  }

  public static void deactivateEnv() {
    useMyEnv = false;
  }

  public static void setWorkingDir (STRUCT sWorkingDir) throws Exception {
    fWorkingDir =  new File((String)sWorkingDir.getAttributes()[0]);
  }

  public static STRUCT getWorkingDir() throws Exception {
    if (fWorkingDir != null) {
      STRUCT   oraFileType = null;

      oFileType[0] = fWorkingDir.getAbsolutePath();
      if (fWorkingDir.exists()) {
        oFileType[1] = fWorkingDir.getName();
        oFileType[2] = new BigDecimal(fWorkingDir.length());
        oFileType[3] = new java.sql.Timestamp(fWorkingDir.lastModified());
        oFileType[4] = (fWorkingDir.isDirectory()?"Y":"N");
        try {
          oFileType[5] = (fWorkingDir.canWrite()?"Y":"N");
        } catch (SecurityException e) {
          oFileType[5] = "N";
        }
        oFileType[6] = (fWorkingDir.canRead()?"Y":"N");
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
      oraFileType = new STRUCT(sDescr, con, oFileType);
      return oraFileType;
    } else {
      return null;
    }
  }

  public static void clearWorkingDir () {
    fWorkingDir = null;
  }

  public static void addEnvVar(String sEnvVarName, String sEnvVarValue) {
    vEnvVars.put(sEnvVarName, sEnvVarValue);
  }

  public static void removeEnvVar(String sEnvVarName) {
    vEnvVars.remove(sEnvVarName);
  }

  public static void clearEnv() {
    vEnvVars.clear();
  }

  public static void loadEnv(String envName) {
    vEnvVars.put(envName, System.getenv(envName));
  }

  public static void loadEnv() {
    vEnvVars.putAll(System.getenv());
  }

  public static String getEnvVar(String sEnvVarName) {
    return (String)vEnvVars.get(sEnvVarName);
  }

  private static String[] getEnvAsArray() {
   String[] envVars = new String[vEnvVars.size()];
   String   sVarName;
   int i = 0;

   Enumeration eEnvVarNames = vEnvVars.keys();
   while (eEnvVarNames.hasMoreElements()) {
     sVarName = (String)eEnvVarNames.nextElement();
     envVars[i++] = sVarName + "=" + (String)vEnvVars.get(sVarName);
   }
   return envVars;
  }

  private static ReturnData doExec(String sCommand, Datum data, int iReturnType) throws Exception {
    Datum               tempLob;

    if (iReturnType == oracle.jdbc.OracleTypes.BLOB) {
      tempLob = BLOB.createTemporary(con, true, BLOB.DURATION_CALL);
    } else if (iReturnType == oracle.jdbc.OracleTypes.CLOB) {
      tempLob = CLOB.createTemporary(con, true, CLOB.DURATION_CALL);
    } else {
      tempLob = null;
    }

    return doit(sCommand, data, tempLob);
  }

  private static ReturnData doit(String sCommand, Datum data, Datum tempLob) throws Exception {
    return doit(sCommand, data, tempLob, gbUseShell);
  }


  private static ReturnData doit(String sCommand, Datum data, Datum tempLob, Datum errLob) throws Exception {
    return  doit(sCommand, data, tempLob, errLob, gbUseShell);
  }

  private static ReturnData doit(String sCommand, Datum stdInLob, Datum stdOutLob, boolean executeInShell) throws Exception {
    return doit(sCommand, stdInLob, stdOutLob, null, executeInShell);
  }

  private static ReturnData doit(String sCommand, Datum stdInLob, Datum stdOutLob, Datum stdErrLob, boolean executeInShell) throws Exception {
    Process             p = null;

    InputStreamReader   pStdOutR = null;
    InputStream         pStdOutS = null;
    InputStreamReader   pStdErrR = null;
    InputStream         pStdErrS = null;
    OutputStreamWriter  pStdInW  = null;
    OutputStream        pStdInS  = null;

    Writer              dStdOutW = null;
    OutputStream        dStdOutS = null;
    Writer              dStdErrW = null;
    OutputStream        dStdErrS = null;
    Reader              dStdInR  = null;
    InputStream         dStdInS  = null;

    char[] caStdInBuffer = null;
    byte[] baStdInBuffer = null;
    char[] caStdOutBuffer = null;
    byte[] baStdOutBuffer = null;
    char[] caStdErrBuffer = null;
    byte[] baStdErrBuffer = null;

    int iCharsRead = 0;
    ReturnData oReturnstdInLob = new ExternalCall.ReturnData();


    if (stdOutLob == null) {
      // do nothing here ...
    } else if (stdOutLob instanceof oracle.sql.BLOB) {
      dStdOutS = ((BLOB)stdOutLob).getBinaryOutputStream(0L);
      baStdOutBuffer = new byte[((BLOB)stdOutLob).getChunkSize()];
    } else if (stdOutLob instanceof oracle.sql.CLOB) {
      dStdOutW = ((CLOB)stdOutLob).getCharacterOutputStream(0L);
      caStdOutBuffer = new char[((CLOB)stdOutLob).getChunkSize()];
    }

    if (stdErrLob == null) {
      // do nothing here ...
    } else if (stdErrLob instanceof oracle.sql.BLOB) {
      dStdErrS = ((BLOB)stdErrLob).getBinaryOutputStream(0L);
      baStdErrBuffer = new byte[((BLOB)stdErrLob).getChunkSize()];
    } else if (stdErrLob instanceof oracle.sql.CLOB) {
      dStdErrW = ((CLOB)stdErrLob).getCharacterOutputStream(0L);
      caStdErrBuffer = new char[((CLOB)stdErrLob).getChunkSize()];
    }

    if (stdInLob != null) {
      if (stdInLob instanceof oracle.sql.BLOB) {
        dStdInS = ((BLOB)stdInLob).getBinaryStream();
        baStdInBuffer = new byte[((BLOB)stdInLob).getChunkSize()];
      } else if (stdInLob instanceof oracle.sql.CLOB) {
        dStdInR  = ((CLOB)stdInLob).getCharacterStream();
        caStdInBuffer = new char[((CLOB)stdInLob).getChunkSize()];
      } else {
        // do nothing
      }
    }

    if (executeInShell) {
      String saCommand[] = new String[3];
      saCommand[0] = gsShellPath;
      saCommand[1] = gsShellSwitch;
      saCommand[2] = sCommand;
      p = Runtime.getRuntime().exec(saCommand, (useMyEnv?getEnvAsArray():null), fWorkingDir);
    } else {
      p = Runtime.getRuntime().exec(sCommand, (useMyEnv?getEnvAsArray():null), fWorkingDir);
    }
    iCharsRead = 0;

    if (stdInLob != null) {
      if (stdInLob instanceof oracle.sql.BLOB) {
        pStdInS = p.getOutputStream();
        while ((iCharsRead = dStdInS.read(baStdInBuffer, 0, baStdInBuffer.length)) != -1) {
          pStdInS.write(baStdInBuffer, 0, iCharsRead);
        }
        dStdInS.close();
        pStdInS.flush();
        pStdInS.close();
      } else if (stdInLob instanceof oracle.sql.CLOB) {
        pStdInW = new OutputStreamWriter(p.getOutputStream());
        while ((iCharsRead = dStdInR.read(caStdInBuffer, 0, caStdInBuffer.length)) != -1) {
          pStdInW.write(caStdInBuffer, 0, iCharsRead);
        }
        dStdInR.close();
        pStdInW.flush();
        pStdInW.close();
      }
    }

    Thread  outAccumulator = null;
    Thread  errAccumulator = null;

    if (stdOutLob == null) {
      outAccumulator = new StreamAccumulator(p.getInputStream());
	     errAccumulator = new StreamAccumulator(p.getErrorStream());
    } else if (stdOutLob instanceof oracle.sql.CLOB) {
      outAccumulator = new StreamReaderAccumulator(p.getInputStream(), dStdOutW);
      if (stdErrLob == null) {
	       errAccumulator = new StreamReaderAccumulator(p.getErrorStream(), dStdOutW);
      } else {
	       errAccumulator = new StreamReaderAccumulator(p.getErrorStream(), dStdErrW);
      }
    } else if (stdOutLob instanceof oracle.sql.BLOB) {
      outAccumulator = new StreamAccumulator(p.getInputStream(), dStdOutS);
      if (stdErrLob == null) {
	       errAccumulator = new StreamAccumulator(p.getErrorStream(), dStdOutS);
      } else {
	       errAccumulator = new StreamAccumulator(p.getErrorStream(), dStdErrS);
      }
    }

    try {
      outAccumulator.start();
      errAccumulator.start();

      p.waitFor();

      outAccumulator.join();
      errAccumulator.join();
	   } catch (Throwable t) {}

    try {
      dStdOutW.flush();
      dStdOutW.close();
    } catch (Exception e) {}
    try {
      dStdOutS.flush();
      dStdOutS.close();
    } catch (Exception e) {}
    try {
      dStdErrW.flush();
      dStdErrW.close();
    } catch (Exception e) {}
    try {
      dStdErrS.flush();
      dStdErrS.close();
    } catch (Exception e) {}

    oReturnstdInLob.stdout = stdOutLob;
    oReturnstdInLob.stderr = stdErrLob;
    oReturnstdInLob.returnCode = p.exitValue();
    return oReturnstdInLob;
  }


  public static Datum execClob(String sCommand, CLOB dataClob) throws Exception {
    return doExec(sCommand, dataClob, oracle.jdbc.OracleTypes.CLOB).stdout;
  }

  public static Datum execClob(String sCommand, BLOB dataBlob) throws Exception {
    return doExec(sCommand, dataBlob, oracle.jdbc.OracleTypes.CLOB).stdout;
  }

  public static Datum execBlob(String sCommand, BLOB dataBlob) throws Exception {
    return doExec(sCommand, dataBlob, oracle.jdbc.OracleTypes.BLOB).stdout;
  }

  public static Datum execBlob(String sCommand, CLOB dataClob) throws Exception {
    return doExec(sCommand, dataClob, oracle.jdbc.OracleTypes.BLOB).stdout;
  }

  public static Datum execClob(String sCommand) throws Exception {
    return doExec(sCommand, null, oracle.jdbc.OracleTypes.CLOB).stdout;
  }

  public static Datum execBlob(String sCommand) throws Exception {
    return doExec(sCommand, null, oracle.jdbc.OracleTypes.BLOB).stdout;
  }


  public static int exec(String sCommand, CLOB dataClob) throws Exception {
    return doExec(sCommand, dataClob, oracle.jdbc.OracleTypes.NULL).returnCode;
  }

  public static int exec(String sCommand, BLOB dataBlob) throws Exception {
    return doExec(sCommand, dataBlob, oracle.jdbc.OracleTypes.NULL).returnCode;
  }

  public static int exec(String sCommand) throws Exception {
    return doExec(sCommand, null, oracle.jdbc.OracleTypes.NULL).returnCode;
  }

  public static int execOut(String sCommand, CLOB dataClob, CLOB returnClob) throws Exception {
    return doit(sCommand, dataClob, returnClob).returnCode;
  }

  public static int execOut(String sCommand, BLOB dataBlob, CLOB returnClob) throws Exception {
    return doit(sCommand, dataBlob, returnClob).returnCode;
  }

  public static int execOut(String sCommand, BLOB dataBlob, BLOB returnBlob) throws Exception {
    return doit(sCommand, dataBlob, returnBlob).returnCode;
  }

  public static int execOut(String sCommand, CLOB dataClob, BLOB returnBlob) throws Exception {
    return doit(sCommand, dataClob, returnBlob).returnCode;
  }


  public static int execOutErr(String sCommand, CLOB dataClob, CLOB returnClob, CLOB errorClob) throws Exception {
    return doit(sCommand, dataClob, returnClob, errorClob).returnCode;
  }

  public static int execOutErr(String sCommand, BLOB dataClob, CLOB returnClob, CLOB errorClob) throws Exception {
    return doit(sCommand, dataClob, returnClob, errorClob).returnCode;
  }

  public static int execOutErr(String sCommand, BLOB dataClob, BLOB returnClob, BLOB errorClob) throws Exception {
    return doit(sCommand, dataClob, returnClob, errorClob).returnCode;
  }

  public static int execOutErr(String sCommand, CLOB dataClob, BLOB returnClob, BLOB errorClob) throws Exception {
    return doit(sCommand, dataClob, returnClob, errorClob).returnCode;
  }

  public static int execOut(String sCommand, BLOB returnBlob) throws Exception {
    return doit(sCommand, null, returnBlob).returnCode;
  }

  public static int execOut(String sCommand, CLOB returnClob) throws Exception {
    return doit(sCommand, null, returnClob).returnCode;
  }

  public static int execOutErr(String sCommand, BLOB returnBlob, BLOB errorBlob) throws Exception {
    return doit(sCommand, null, returnBlob, errorBlob).returnCode;
  }

  public static int execOutErr(String sCommand, CLOB returnBlob, CLOB errorBlob) throws Exception {
    return doit(sCommand, null, returnBlob, errorBlob).returnCode;
  }




}
/
