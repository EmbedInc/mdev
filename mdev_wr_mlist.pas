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
  abort, abort2, err_atline;

%include 'wbuf_local.ins.pas';
{
****************************************
*
*   Private subroutine ADD_MODULE (FW, MOD, STAT)
*
*   Add the relocatable binarie from the module MOD to the MLIST list.
}
procedure add_module (                 {add binaries from a module}
  in      fw: mdev_fw_t;               {the firmware being built}
  in      mod: mdev_mod_t;             {the module to add binaries from}
  out     stat: sys_err_t);
  val_param; internal;

var
  ent_p: mdev_file_ent_p_t;            {buildable files list entry}
  dir: string_treename_t;              {directory containing buildable file}
  gnam: string_leafname_t;             {buildable file leafname without suffix}
  suff: mdev_suffix_k_t;               {file name suffix ID}

begin
  dir.max := size_char(dir.str);       {init local var strings}
  gnam.max := size_char(gnam.str);

  if mod.build_p = nil then begin      {no explicit files, use default module name}
    string_copy (fw.name_p^, buf);     {init list entry with firmware name}
    string_append1 (buf, '_');
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add MDEV module name}
    in_list (mlist, buf);              {make sure this module in list}
    return;
    end;
{
*   This module has a explicitly list of buildable files.  We assume each
*   results in a binary to add to the list.
}
  ent_p := mod.build_p;                {init to first buildable files list entry}
  while ent_p <> nil do begin          {scan the list}
    if ent_p^.file_p^.name_p^.len > 0 then begin {non-empty file name ?}
      mdev_file_suffix (               {find components of buildable file name}
        ent_p^.file_p^.name_p^,        {file treename to find components of}
        dir,                           {directory containing the file}
        gnam,                          {generic file name, without suffix}
        suff,                          {file name suffix ID}
        stat);
      if sys_error(stat) then return;
      case suff of                     {what kind of file is it ?}
mdev_suffix_dspic_k: begin             {.DSPIC}
          string_copy (gnam, buf);     {use generic file name directly}
          end;
mdev_suffix_xc16_k: begin              {.XC16}
          string_copy (gnam, buf);     {init with generic file name}
          string_appends (buf, '_c');  {add suffix for coming from C source}
          end;
otherwise                              {unrecognized suffix}
        writeln ('*** INTERNAL ERROR in MDEV_WR_MLIST > ADD_MODULE ***');
         writeln ('  File name suffix ID ', ord(suff), ' is not implemented.');
        sys_bomb;
        end;
      in_list (mlist, buf);            {make sure this module is in the list}
      end;                             {end of filename not empty case}
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
  file_open_read_text (                {open the MLIST file}
    fnam, '',                          {file name and suffixes}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_list_init (                   {init the modules list}
    mlist, util_top_mem_context);
  mlist.deallocable := false;          {will not individually deallocate lines}

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
{
*   Make sure the MDEV modules are in the list.
}
  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan the assigned IDs}
    if not fw.modids[id].used then next; {no module included with this ID}
    add_module (fw, fw.modids[id].mod_p^, stat); {add binaries from this module}
    if sys_error(stat) then goto abort2;
    end;                               {back for next ID}
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
