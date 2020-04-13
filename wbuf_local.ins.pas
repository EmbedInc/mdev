{
********************************************************************************
*
*   Internal subroutine WBUF (STAT)
*
*   Write the current output buffer contents to the file.  Reset the output
*   buffer to empty.
}
procedure wbuf (                       {write buffer to file, reset buf to empty}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  file_write_text (buf, conn, stat);   {write the current line to the output file}
  buf.len := 0;                        {reset the current output line to empty}
  end;
