module mdev_show;
define mdev_show_desc;
define mdev_show;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine SKIP_BLANKS (STR, P)
*
*   Skip over blanks in the string STR.  P is the current string index.  It will
*   be returned the index of the next non-blank at or after the starting
*   position.  P is set to the length of STR plus 1 when STR is exhausted.
}
procedure skip_blanks (                {skip over blanks at current location}
  in      str: univ string_var_arg_t;  {the string to skip blanks in}
  in out  p: string_index_t);          {index into STR}
  val_param; internal;

begin
  while
      (p <= str.len) and then          {still within string ?}
      (str.str[p] = ' ')               {at a blank ?}
      do begin
    p := p + 1;                        {advance to next character}
    end;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_DESC (DESC, INDENT)
*
*   Show the scription string DESC on standard output.  It will be wrapped as
*   needed, and each line will be indented INDENT spaces.
}
procedure mdev_show_desc (             {show description text}
  in      desc: univ string_var_arg_t; {description string, may be long}
  in      indent: sys_int_machine_t);  {number of space to indent each new line}
  val_param;

const
  maxcol = 80;                         {max allowed output column}

var
  ln: string_var80_t;                  {one line output buffer}
  p: string_index_t;                   {input line line parse index}
  bl: string_index_t;                  {index of next input string blank}
  ii: sys_int_machine_t;               {scratch integer}

begin
  ln.max := min(maxcol, size_char(ln.str)); {init local var string}
  if indent >= ln.max then return;     {no columns left to write to, give up ?}

  ln.len := 0;                         {init output line to empty}
  for ii := 1 to indent do begin       {write indentation to output line}
    string_append1 (ln, ' ');
    end;

  p := 1;                              {init input line parse index}
  skip_blanks (desc, p);               {skip over leading blanks}

  while p <= desc.len do begin         {back here each new input string "word"}
    bl := p + 1;                       {init index of first char after this word}
    while                              {search for end of this word}
        (bl <= desc.len) and then      {still within string ?}
        (desc.str[bl] <> ' ')          {not at a blank ?}
        do begin
      bl := bl + 1;                    {go to next char}
      end;
    ii := bl - p;                      {length of this word}

    if                                 {write existing line, start new ?}
        (ln.len > indent) and          {this line has some content ?}
        ((ln.len + 1 + ii) > ln.max)   {this word would cause overflow ?}
        then begin
      writeln (ln.str:ln.len);         {write this line}
      ln.len := indent;                {reset line to just indentation}
      end;

    string_append1 (ln, ' ');          {write blank after previous word}
    while p < bl do begin              {copy this word to the output line}
      string_append1 (ln, desc.str[p]); {copy this character}
      p := p + 1;                      {advance to next character}
      end;

    skip_blanks (desc, p);             {skip over blanks after end of word}
    end;                               {back to do next input string word}

  if ln.len > indent then begin        {there is a partial unwritten line ?}
    writeln (ln.str:ln.len);           {write it}
    end;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW (MD, INDENT)
*
*   Show all the data in the MDEV library use instance, MD.  INDENT is the
*   number of spaces the whole output will be indented.
}
procedure mdev_show (                  {show all MDEV data}
  in      md: mdev_t;                  {library use instance to show data of}
  in      indent: sys_int_machine_t);  {indentation level, 0 for none}
  val_param;

begin
  writeln;
  writeln ('':indent, 'Directories:');
  mdev_show_list_dir (md.dir_p, indent+2, true);

  writeln;
  writeln ('':indent, 'Interfaces:');
  mdev_show_list_iface (md.iface_p,  indent+2, true);

  writeln;
  writeln ('':indent, 'Files:');
  mdev_show_list_file (md.file_p,  indent+2, true);

  writeln;
  writeln ('':indent, 'Modules:');
  mdev_show_list_mod (md.mod_p,  indent+2, true);

  writeln;
  writeln ('':indent, 'Firmwares:');
  mdev_show_list_fw (md.fw_p,  indent+2, true);
  end;
