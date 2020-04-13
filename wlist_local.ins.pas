{   Convenience routines for writing sorted lines to a file.  This file is
*   intended to be included directly in each module that uses these routines.
*   They therefore become local routines with access to local variables that do
*   not need to be passed on the command line.
*
*   This module requires the following local state:
*
*     CONN  -  Connection to the output file.
*
*     BUF  -  One line output buffer.
*
*     OUTLIST  -  String list.  Individual deallocation not needed.
}
%include 'wbuf_local.ins.pas';
{
********************************************************************************
*
*   Internal subroutine OUTLIST_START
*
*   Start a new use of the strings list OUTLIST.  The list must not already be
*   in use.
}
procedure outlist_start;
  val_param; internal;

begin
  string_list_init (outlist, util_top_mem_context); {init the list}
  outlist.deallocable := false;        {won't need to individually deallocate entries}
  end;
{
********************************************************************************
*
*   Internal subroutine OUTLIST_END
*
*   End the use of the strings list OUTLIST.  The list can not be used again
*   until OUTLIST_START is called.
}
procedure outlist_end;
  val_param; internal;

begin
  string_list_kill (outlist);
  end;
{
********************************************************************************
*
*   Internal subroutine LBUF
*
*   Write the output buffer as the next OUTLIST entry, then reset the buffer to
*   empty.  Nothing is done if the output buffer is empty.
}
procedure lbuf;
  val_param; internal;

begin
  if buf.len > 0 then begin
    string_list_str_add (outlist, buf); {add buffer string to list}
    buf.len := 0;                      {reset output buffer to empty}
    end;
  end;
{
********************************************************************************
*
*   Internal subroutine WSORT (STAT)
*
*   Sort the list contents, then write the list to the output file.
}
procedure wsort (                      {sort list, write to output file}
  out     stat: sys_err_t);            {completion status}
  val_param; internal;

begin
  sys_error_none (stat);               {init to no error}

  string_list_sort (                   {sort the lines in the list}
    outlist,                           {the list to sort}
    [string_comp_num_k]);              {sort numeric fields numerically}

  string_list_pos_start (outlist);     {position to before first list entry}
  while true do begin                  {back here each new list entry}
    string_list_pos_rel (outlist, 1);  {to next list entry}
    if outlist.str_p = nil then return;
    file_write_text (outlist.str_p^, conn, stat); {write this list entry}
    if sys_error(stat) then return;
    end;                               {back for next list entry}
  end;
