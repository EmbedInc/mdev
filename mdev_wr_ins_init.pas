module mdev_wr_ins;
define mdev_wr_ins_init;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_INS_INIT (FW, VERBOSE, STAT)
*
*   Write the fwname_INIT_MDEV.INS.DSPIC include file.  This file contains code
*   to initialize all the MDEV modules.
}
procedure mdev_wr_ins_init (           {write initialization include file}
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

label
  abort;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);

  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_init_mdev.ins.dspic'(0)); {add fixed part of file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  ent_p := fw.mod_p;                   {init to first modules list entry}
  while ent_p <> nil do begin          {scan the list}
    mod_p := ent_p^.mod_p;             {get pointer to this module}
    string_vstring (buf,               {init fixed part of line}
      '         gcall   '(0), -1);
    string_append (buf, mod_p^.cfgent_p^); {config routine name}
    wbuf (stat);                       {write this line to the output file}
    if sys_error(stat) then goto abort;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to process this new list entry}

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
