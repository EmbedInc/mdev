{
********************************************************************************
*
*   Internal subroutine WBUF
*
*   Write the current output buffer contents to the file.  Reset the output
*   buffer to empty.  STAT is set.
}
procedure wbuf;
  val_param; internal;

begin
  file_write_text (buf, conn, stat);   {write the current line to the output file}
  buf.len := 0;                        {reset the current output line to empty}
  end;
