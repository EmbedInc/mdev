module mdev_wr_templ;
define mdev_wr_templ_list;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine GET_TEMPLATE (FW, TEMPL, VERBOSE, STAT)
*
*   Make sure the modified local copy of the template file TEMPL exists.  FW is
*   the firmware to modify the template for.
}
procedure get_template (               {make sure modified local template copy exists}
  in      fw: mdev_fw_t;               {firmware the template is for}
  in      templ: univ string_var_arg_t; {template source file name}
  in      verbose: boolean;            {show more than just changes}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  dnam: string_leafname_t;             {destination file name}
  fnam: string_treename_t;             {scratch file name}
  tk: string_var8192_t;                {scratch token and string}
  ind: string_index_t;                 {string index}
  ii: sys_int_machine_t;               {scratch integer}
  tf: boolean;                         {true/false returned by program}
  exstat: sys_sys_exstat_t;            {program exit status code}

begin
  dnam.max := size_char(dnam.str);     {init local var strings}
  fnam.max := size_char(fnam.str);
  tk.max := size_char(tk.str);

  string_pathname_split (templ, tk, fnam); {get source file leafname into FNAM}
  string_downcase (fnam);              {force it all lower case for pattern matching}
  string_vstring (tk, 'qqq'(0), -1);   {pattern to look for}
  string_find (tk, fnam, ind);         {look for the pattern in source file name}
  if ind = 0
    then begin                         {source file name does not contain pattern}
      string_pathname_split (templ, tk, dnam); {use template file leafname directly}
      end
    else begin                         {source file name contains pattern at IND}
      string_pathname_split (templ, dnam, fnam); {get template leafname into FNAM}
      string_substr (                  {copy part of filename before pattern}
        fnam,                          {source string}
        1,                             {starting index to copy from}
        ind - 1,                       {ending index to copy from}
        dnam);                         {output string}
      string_append (dnam, fw.name_p^); {add firmware name in place of template}
      ind := ind + tk.len;             {first index after pattern in source string}
      string_substr (                  {get part of source string after pattern}
        fnam,                          {source string}
        ind,                           {starting index to copy from}
        fnam.len,                      {ending index to copy from}
        tk);                           {returned substring}
      string_append (dnam, tk);        {add the substring to end of dest fnam}
      end
    ;
{
*   The destination file name is in DNAM.
}
  if file_exists (dnam) then return;   {modified template already exists ?}
  writeln ('Writing ', dnam.str:dnam.len);

  string_vstring (tk, 'copya -in '(0), -1); {init command line to run COPYA}
  string_append_token (tk, templ);     {add source file name}
  string_appends (tk, ' -out '(0));
  string_append_token (tk, dnam);      {add destination file name}
  {
  *   QQ1 --> top level directory in (cog)source.
  }
  string_appends (tk, ' -repl qq1 '(0));
  sys_envvar_get (string_v('srcdir'), fnam, stat);
  if sys_error(stat) then return;
  string_append_token (tk, fnam);
  {
  *   QQ2 --> firmware name.
  }
  string_appends (tk, ' -repl qq2 '(0));
  string_append_token (tk, fw.name_p^);
  {
  *   QQ3 --> source module generic name.
  }
  string_appends (tk, ' -repl qq3 '(0));
  fnam.len := 0;                       {init substitution string}
  ii := 1;                             {init index to examine file name at}
  while ii <= dnam.len do begin        {look for first underscore}
    if dnam.str[ii] = '_' then exit;
    ii := ii + 1;
    end;
  ii := ii + 1;                        {first char to copy}
  while ii <= dnam.len do begin        {copy up to first "."}
    if dnam.str[ii] = '.' then exit;
    string_append1 (fnam, dnam.str[ii]);
    ii := ii + 1;
    end;
  string_append_token (tk, fnam);
  {
  *   QQ4 --> PIC model.
  }
  string_appends (tk, ' -repl qq4 '(0));
  sys_envvar_get (string_v('pictype'), fnam, stat);
  if sys_error(stat) then return;
  string_append_token (tk, fnam);
  {
  *   QQ5 --> Directory path from immediate SOURCE subdir to FW dir.
  }
  string_appends (tk, ' -repl qq5 '(0));
  sys_envvar_get (string_v('buildname'), fnam, stat);
  if sys_error(stat) then return;
  string_append_token (tk, fnam);

  if verbose then begin
    writeln ('Run: ', tk.str:tk.len);
    end;

  sys_run_wait_stdsame (               {run the command, wait for done}
    tk,                                {the command line to run}
    tf,                                {true/false returned by program}
    exstat,                            {program's exit status code}
    stat);
  end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_TEMPL_LIST (FW, VERBOSE, STAT)
*
*   Create the MDEV module source files that are modified from templates.  These
*   files are only created if they do not previously exist.
}
procedure mdev_wr_templ_list (         {write the source files modified from templates}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  fent_p: mdev_file_ent_p_t;           {pointer to template files list entry}

begin
  sys_error_none (stat);               {init to no error encountered}

  fent_p := fw.templ_p;                {init to first template files list entry}
  while fent_p <> nil do begin         {scan the template files list}
    get_template (                     {process this template}
      fw, fent_p^.file_p^.name_p^, verbose, stat);
    if sys_error(stat) then return;
    fent_p := fent_p^.next_p;          {to next template files list entry}
    end;                               {back to process this new list entry}
  end;
