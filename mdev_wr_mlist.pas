module mdev_wr_mlist;
define mdev_wr_mlist;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine IN_LIST (LIST, MOD)
*
*   Make sure the list LIST contains a entry for the module named MOD.  The
*   actual list entry has ".o" appended to the module name.  The module is added
*   to the end of the list if it is not already in the list.
}
procedure in_list (                    {make sure module is in list}
  in out  list: string_list_t;         {the list}
  in      mod: univ string_var_arg_t); {module name}
  val_param; internal;

var
  lent: string_var80_t;                {actual list entry text}

begin
  lent.max := size_char(lent.str);     {init local var string}

  string_copy (mod, lent);             {init list entry text with module name}
  string_appends (lent, '.o'(0));      {make full list entry text for this module}

  string_list_pos_start (list);        {go to before first list entry}
  while true do begin                  {scan the list}
    string_list_pos_rel (list, 1);     {to next list entry}
    if list.str_p = nil then exit;     {hit end of list ?}
    if string_equal (list.str_p^, lent) then return; {module already in list ?}
    end;                               {back to check next list entry}

  string_list_pos_last (list);         {to last line of list}
  string_list_str_add (list, lent);    {write new entry at end of list}
  end;
{
********************************************************************************
*
*   Local subroutine ADD_FILE (LIST, BNAM, STAT)
*
*   Add the relocatable binary resulting from building the file FNAM to the list.
}
procedure add_file (                   {add result of buildable file to list}
  in out  list: string_list_t;         {the list to add built result to}
  in      bnam: univ string_var_arg_t; {name of buildable object}
  out     stat: sys_err_t);
  val_param; internal;

var
  fnam: string_treename_t;             {scratch file name}
  gnam: string_leafname_t;             {buildable file leafname without suffix}
  suff: mdev_suffix_k_t;               {file name suffix ID}

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  gnam.max := size_char(gnam.str);

  mdev_file_suffix (                   {find components of buildable file name}
    bnam,                              {file name to find components of}
    fnam,                              {returned directory containing the file, unused}
    gnam,                              {returned generic file name, without suffix}
    suff,                              {returned file name suffix ID}
    stat);
  if sys_error(stat) then return;
{
*   GNAM is the generic leafname of the buildable file, and SUFF is the ID of
*   its suffix.
*
*   Now set FNAM to the resulting name of the derived binary.
}
  case suff of                         {what kind of file is it ?}
mdev_suffix_dspic_k,                   {.DSPIC}
mdev_suffix_aspic_k: begin             {.ASPIC}
      string_copy (gnam, fnam);        {use generic file name directly}
      end;
mdev_suffix_xc16_k: begin              {.XC16}
      string_copy (gnam, fnam);        {init with generic file name}
      string_appends (fnam, '_c');     {add suffix for coming from C source}
      end;
otherwise                              {unrecognized suffix}
    sys_stat_set (mdev_subsys_k, mdev_stat_filenbuild_k, stat); {file not builable type}
    sys_stat_parm_vstr (fnam, stat);   {file name}
    return;
    end;
{
*   Make sure the derived binary with generic name FNAM is in the list.
}
  in_list (list, fnam);                {make sure this derived object is in the list}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_MLIST (FW, VERBOSE, STAT)
*
*   Edit the MLIST file for the firmware FW to include all the MDEV modules.
*   The file is always read, then overwritten, with the modules in alphabetic
*   order.
}
procedure mdev_wr_mlist (              {edit MLIST file to include MDEV modules}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line input and output buffer}
  fnam: string_treename_t;             {scratch file name}
  p: string_index_t;                   {BUF parse index}
  tk: string_var32_t;                  {scratch token}
  mlist: string_list_t;                {list of modules in MLIST file}
  pick: sys_int_machine_t;             {number of token picked from list}
  id: sys_int_machine_t;               {assigned module ID}

label
  done_read, abort, abort2, err_atline;

%include 'wbuf_local.ins.pas';
{
****************************************
*
*   Private subroutine ADD_FROM_LIST
*
*   Add the linkable result of each file in a list to the MLIST list.
}
procedure add_from_list(               {add binaries from a MDEV}
  in      flist_p: mdev_file_ent_p_t;  {pointer to files list}
  out     stat: sys_err_t);
  val_param; internal;

var
  ent_p: mdev_file_ent_p_t;            {buildable files list entry}

begin
  ent_p := flist_p;                    {init to first file in list}
  while ent_p <> nil do begin          {scan the list}
    add_file (mlist, ent_p^.file_p^.name_p^, stat); {add derived result to MLIST}
    if sys_error(stat) then return;
    ent_p := ent_p^.next_p;            {advance to next buildable files list entry}
    end;                               {back to process this new list entry}
  end;
{
****************************************
*
*   Start of main routine.
}
begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);
  tk.max := size_char(tk.str);

  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '.mlist'(0));  {add fixed part of file name}
{
*   Read the MLIST file and save the module names in MLIST.
}
  string_list_init (                   {init the modules list}
    mlist, util_top_mem_context);
  mlist.deallocable := false;          {will not individually deallocate lines}

  file_open_read_text (                {open the MLIST file}
    fnam, '',                          {file name and suffixes}
    conn,                              {returned connection to the file}
    stat);
  if file_not_found(stat) then goto done_read; {nothing to read ?}
  if sys_error(stat) then goto abort2;

  while true do begin                  {loop over the MLIST file lines}
    file_read_text (conn, buf, stat);  {read the next MLIST file line}
    if file_eof(stat) then exit;       {hit end of file ?}
    if sys_error(stat) then goto abort;
    string_unpad (buf);                {remove trailing spaces from the line}
    if buf.len <= 0 then next;         {ignore blank lines}
    p := 1;                            {init input line parse index}
    string_token (buf, p, tk, stat);   {get the command keyword}
    if sys_error(stat) then goto abort;
    string_upcase (tk);                {to upper case to make case-insensitive}
    string_tkpick80 (tk,               {pick command keyword from list}
      'ADDMOD',
      pick);
    case pick of                       {which command is it ?}
1:    begin                            {ADDMOD objectfile}
        string_token (buf, p, tk, stat); {get the module file name}
        if sys_error(stat) then goto abort;
        if tk.len >= 3 then begin
          if (tk.str[tk.len-1] = '.') and (tk.str[tk.len] = 'o') then begin
            tk.len := tk.len - 2;      {remove ".o" suffix}
            end;
          end;
        in_list (mlist, tk);           {make sure this module is in the list}
        end;
otherwise
      sys_stat_set (mdev_subsys_k, mdev_stat_mlcmd_k, stat);
      sys_stat_parm_vstr (tk, stat);
      goto err_atline;
      end;                             {end of MLIST file command cases}
    string_token (buf, p, tk, stat);   {try to get another token from this line}
    if not string_eos(stat) then begin {unread token at end of line ?}
      sys_stat_set (mdev_subsys_k, mdev_stat_extra_k, stat);
      sys_stat_parm_vstr (tk, stat);
      goto err_atline;
      end;
    end;                               {back to read next line from MLIST file}
  file_close(conn);                    {close the MLIST file}

done_read:
{
*   Make sure the derived objects from the buildable files of all modules
*   in this firmware are in MLIST.
}
  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan the assigned IDs}
    if not fw.modids[id].used then next; {no mdev included with this ID}
    add_from_list (                    {add derived objects to MLIST}
      fw.modids[id].mod_p^.build_p,    {list of buildable files}
      stat);
    if sys_error(stat) then goto abort2;
    end;                               {back for next ID}
{
*   Make sure the result of building all the template files is in MLIST.
}
  add_from_list (                      {add derived objects to MLIST}
    fw.tmbld_p,                        {list of buildable objects}
    stat);
  if sys_error(stat) then goto abort2;
{
*   Sort the list.  This way there are no net changes to the file when the
*   content doesn't change.
}
  string_list_sort (                   {sort the modules list}
    mlist,                             {the list to sort}
    [ string_comp_lcase_k,             {lower case right before upper same}
      string_comp_num_k]);             {sort numeric fields numerically}
{
*   Re-write the MLIST file from the list contents.
}
  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_list_pos_start (mlist);       {go to before first list entry}
  while true do begin                  {back here each new list entry}
    string_list_pos_rel (mlist, 1);    {to next list entry}
    if mlist.str_p = nil then exit;    {hit end of list ?}
    string_vstring (buf, 'ADDMOD '(0), -1); {command name}
    string_append (buf, mlist.str_p^); {add the module name}
    wbuf (stat);
    if sys_error(stat) then goto abort;
    end;                               {back for next list entry}

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}

abort2:                                {modules list exists}
  string_list_kill (mlist);            {delete list, deallocate resources}
  return;

err_atline:                            {add line number and file name to STAT, then abort}
  sys_stat_parm_int (conn.lnum, stat);
  sys_stat_parm_vstr (conn.tnam, stat);
  goto abort;
  end;
