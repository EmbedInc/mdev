module mdev_wr_build;
define mdev_wr_build;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine APPEND_NAMES (STR, PATH, STAT)
*
*   Find each of the pathname parts after the (cog)source directory to the
*   final file name.  These are appended to STR as separate tokens.
*
*   This routine calls itself recursively to append all but the leafname.  The
*   recursion ends when PATH ends directly in (cog)source.
}
procedure append_names (               {append names of PATH to STR}
  in out  str: univ string_var_arg_t;  {the string to append path parts to}
  in      path: string_treename_t;     {pathname to append parts of}
  in out  stat: sys_err_t);            {completion status, assumed no err on entry}
  val_param; internal;

var
  dir: string_treename_t;              {directory part of pathname}
  fnam: string_leafname_t;             {leafname part of pathname}
  tnam1, tnam2: string_treename_t;     {scratch treenames}

label
  wrleaf;

begin
  dir.max := size_char(dir.str);       {init local var strings}
  fnam.max := size_char(fnam.str);
  tnam1.max := size_char(tnam1.str);
  tnam2.max := size_char(tnam2.str);

  string_pathname_split (path, dir, fnam); {make directory and leafname components}
{
*   Check for whether recursion ends here.
*
*   The normal case is when PATH is a file or directory directly in (cog)source.
*   This is checked by comparing the expansion of (cog)source/<fnam> to PATH.
*
*   Recursion is also ended when the pathname split above didn't result in
*   anything new.  This is checked by DIR and PATH being equal.  This should not
*   happen since PATH is supposed to be something within (cog)source.  However,
*   this check at least avoid infinite recursion in case of a bad pathname.
}
  if dir.len >= path.len then goto wrleaf; {got to file system top ?}

  string_vstring (tnam1, '(cog)source/'(0), -1); {init fixed part}
  string_append (tnam1, fnam);         {add the leafname}
  string_treename (tnam1, tnam2);      {resolve to full absolute pathname}
  if string_equal (tnam2, path) then goto wrleaf; {hit (cog)source ?}
{
*   DIR contains more pathname components to append to STR before FNAM.
}
  append_names (str, dir, stat);       {append previous components recursively}
  if sys_error(stat) then return;

wrleaf:                                {done with previous components, append leafname}
  string_append_token (str, fnam);     {append the leafname to STR}
  end;
{
********************************************************************************
*
*   Local subroutine APPEND_FNAM (STR, FNAM, STAT)
*
*   Append the source-specific parts of the filename FNAM to the string STR.
*   Each pathname part within (cog)source will be written as a separate token.
}
procedure append_fnam (                {append pathname parts to string}
  in out  str: univ string_var_arg_t;  {the string to append to}
  in     fnam: univ string_var_arg_t;  {the full expanded pathname}
  in out  stat: sys_err_t);            {completion status, assumed no err on entry}
  val_param; internal;

var
  path: string_treename_t;             {local copy of pathname}
  tk: string_var32_t;                  {scratch token}

label
  err;

begin
  path.max := size_char(path.str);     {init local var strings}
  tk.max := size_char(tk.str);

  if fnam.len < 11 then goto err;      {not long enough for "x.ins.dspic" ?}
  string_substr (                      {get end of file name}
    fnam,                              {string to extract from}
    fnam.len - 9,                      {starting index}
    fnam.len,                          {ending index}
    tk);                               {resulting substring}
  if not string_equal(                 {file name doesn't have the right suffix ?}
      string_v('.ins.dspic'(0)),
      tk)
    then goto err;

  path.len := 0;                       {init local pathname to empty}
  string_appendn (                     {make local copy of part without suffix}
    path, fnam.str, fnam.len - 10);

  append_names (str, path, stat);      {append all the pathname parts to STR}
  return;

err:                                   {FNAM doesn't end in ".ins.dspic"}
  sys_stat_set (mdev_subsys_k, mdev_stat_ninsdspic_k, stat);
  sys_stat_parm_vstr (fnam, stat);
  end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_BUILD (FW, VERBOSE, STAT)
*
*   Write the build scripts specific to the MDEV modules in the firmware FW.
*   The following scripts are written:
*
*     build_mdevs_init
*
*       Intended to be called from the BUILD_FWINIT script.  It fetches files
*       required for building MDEV modules, except for the top module source
*       files themselves.
*
*     build_mdevs
*
*       Intended to be called from the BUILD_FW script.  It builds the MDEV
*       source modules.
}
procedure mdev_wr_build (              {write BUILD_MDEVS scripts}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line output buffer}
  fent_p: mdev_file_ent_p_t;           {pointer to one files list entry}
  ment_p: mdev_mod_ent_p_t;            {pointer to one modules list entry}

label
  abort;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
{
*   Write BUILD_MDEVS_INIT.BAT
}
  file_open_write_text (               {open the file}
    string_v('build_mdevs_init.bat'(0)),  '', {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  fent_p := fw.files_p;                {init to first list entry}
  while fent_p <> nil do begin         {scan the list}
    string_vstring (buf, 'call src_get_ins_dspic'(0), -1); {init line for this file}
    append_fnam (buf, fent_p^.file_p^.name_p^, stat); {append pathname tokens}
     if sys_error(stat) then goto abort;
    wbuf;                              {write line for this file}
    if sys_error(stat) then goto abort;
    fent_p := fent_p^.next_p           {to next list entry}
    end;                               {back to process this new list entry}

  file_close (conn);                   {close the file}
{
*   Write BUILD_MDEVS.BAT.
}
  file_open_write_text (               {open the file}
    string_v('build_mdevs.bat'(0)),  '', {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  ment_p := fw.mod_p;                  {init to first modules list entry}
  while ment_p <> nil do begin         {scan the list of modules in this FW}
    string_vstring (                   {init this line to the fixed part}
      buf, 'call src_dspic %srcdir% %fwname%_'(0), -1);
    string_append (buf, ment_p^.mod_p^.name_p^); {add module name}
    wbuf;                              {write the line for this module}
    if sys_error(stat) then goto abort;
    ment_p := ment_p^.next_p;          {to next list entry}
    end;                               {back to process this new list entry}

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
