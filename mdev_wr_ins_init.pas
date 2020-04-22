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
  id: sys_int_machine_t;               {module ID}

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

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if not fw.modids[id].used then next; {this ID not used in this firmware ?}
    string_vstring (buf,               {init fixed part of line}
      '         gcall   '(0), -1);
    string_append (buf, fw.modids[id].mod_p^.cfgent_p^); {config routine name}
    wbuf (stat);                       {write this line to the output file}
    if sys_error(stat) then goto abort;
    end;                               {back to do next ID}

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
