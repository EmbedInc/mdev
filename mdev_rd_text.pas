module mdev_rd_text;
define mdev_rd_text;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_RD_TEXT (MR, STR_P)
*
*   Read a subordinate block of arbitrary wrappable free-flowing text.  There
*   may be multiple lines of text.  The preceeding command has just been read,
*   with the text in a subordinate block that has not been entered yet.
*
*   The contents of the text lines are combined into a single long string.  One
*   space is inserted between the data from successive lines of text.  A string
*   to contain the exact text is allocated, and STR_P is returned pointing to
*   this new string.  STR_P is returned NIL if there are no text lines or they
*   otherwise indicate the empty string.
}
procedure mdev_rd_text (               {read arbitrary wrappable text}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  out     str_p: string_var_p_t);      {returned pointer to new string}
  val_param;

var
  s: string_var8192_t;                 {combined string from all text lines}
  line: string_var8192_t;              {string from one input line}
  stat: sys_err_t;                     {completion status}

begin
  s.max := size_char(s.str);           {init local var strings}
  line.max := size_char(line.str);
  str_p := nil;                        {init to no string returned}

  s.len := 0;                          {init the accumulated line to empty}
  hier_read_block_start (mr.rd);       {go down into the block of text lines}
  while hier_read_line (mr.rd, stat) do begin {back here each new text line}
    hier_read_string (mr.rd, line);    {get text from this line}
    if line.len <= 0 then next;        {no text on this line ?}
    if                                 {need blank before previous content ?}
        (s.len > 0) and then           {there is previous content ?}
        (s.str[s.len] <> ' ')          {isn't already a blank there ?}
        then begin
      string_append1 (s, ' ');         {add blank separator before new text}
      end;
    string_append (s, line);           {add text from this line to accumulated string}
    end;                               {back for next line}

  if s.len <= 0 then return;           {no string to return, don't allocate one ?}

  string_alloc (s.len, mr.md_p^.mem_p^, false, str_p); {allocate the return string}
  string_copy (s, str_p^);             {fill in the return string}
  end;
