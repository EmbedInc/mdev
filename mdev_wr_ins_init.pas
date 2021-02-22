module mdev_wr_ins;
define mdev_wr_ins_init;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_INS_INIT (MD, FW, VERBOSE, STAT)
*
*   Write the include files fwname_CONFIG_MDEVS.INS.DSPIC and
*   fwname_DECONFIG_MDEVS.INS.DSPIC.  The first file contains code to initialize
*   all the MDEV modules.  The second contains the code to de-configure the
*   modules.  Not all modules have de-config entry points.  The de-config
*   routines, when they exist, must be called in reverse order of the config
*   routines.
}
procedure mdev_wr_ins_init (           {write initialization include file}
  in out  md: mdev_t;                  {state for this use of the MDEV library}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line output buffer}
  fnam: string_treename_t;             {scratch file name}
  ent_p: mdev_mod_ent_p_t;             {pointer to current modules list entry}
  mod_p: mdev_mod_p_t;                 {pointer to current module}
  dclist: string_list_t;               {list of de-config entry point names}

label
  abort1, abort2;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);
{
*   Write the file to initialize the modules, and make a list of the de-config
*   entry points at the same time.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_config_mdevs.ins.dspic'(0)); {add fixed part of file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_list_init (dclist, md.mem_p^); {init list of de-config routines}
  dclist.deallocable := false;         {won't individually deallocate entries}

  ent_p := fw.mod_p;                   {init to first modules list entry}
  while ent_p <> nil do begin          {scan the list}
    mod_p := ent_p^.mod_p;             {get pointer to this module}

    if mod_p^.deconfig_p <> nil then begin {this module has de-config routine ?}
      string_list_str_add (dclist, mod_p^.deconfig_p^); {add this routine to list}
      end;

    string_vstring (buf,               {init fixed part of line}
      '         gcall   '(0), -1);
    string_append (buf, mod_p^.cfgent_p^); {config routine name}
    wbuf (stat);                       {write this line to the output file}
    if sys_error(stat) then goto abort2;

    string_vstring (buf,               {write check for failure}
      '         skip_nflag cfgfail'(0), -1);
    wbuf (stat);
    if sys_error(stat) then goto abort2;
    string_vstring (buf,               {failure, abort}
      '         jump    cmdevs_done'(0), -1);
    wbuf (stat);
    if sys_error(stat) then goto abort2;

    ent_p := ent_p^.next_p;            {advance to next list entry}
    if ent_p <> nil then begin         {another config call will be written ?}
      wbuf (stat);                     {leave blank line before next config}
      if sys_error(stat) then goto abort2;
      end;
    end;                               {back to process this new list entry}

  file_close (conn);                   {close the modules initialization file}
{
*   Write the file to call the de-config routines of those modules that have
*   them.  The list of de-config routines is in DCLIST, in reverse order that
*   they need to be called in.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_deconfig_mdevs.ins.dspic'(0)); {add fixed part of file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then goto abort1;

  string_list_pos_last (dclist);       {to last de-config routines list entry}
  while dclist.str_p <> nil do begin   {loop backwards thru de-config routines list}
    string_vstring (buf,               {init fixed part of line}
      '         gcall   '(0), -1);
    string_append (buf, dclist.str_p^); {de-config routine name}
    wbuf (stat);                       {write this line to the output file}
    if sys_error(stat) then goto abort2;

    string_list_pos_rel (dclist, -1);  {to previous de-config routines list entry}
    end;                               {back to process this new list entry}

abort2:                                {file open, list exists, STAT all set}
  file_close (conn);                   {close the file}

abort1:                                {list exists, STAT all set}
  string_list_kill (dclist);           {deallocate de-config routines list}
  end;
