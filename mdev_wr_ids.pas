module mdev_wr_ids;
define mdev_wr_ids;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_IDS (FW, VERBOSE, STAT)
*
*   Write the <fwname>_IDS.MDEV file.  This file hard-codes the assigned MDEV
*   module IDS for the firmare FW.
}
procedure mdev_wr_ids (                {write MDEV file with assigned module IDs}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line output buffer}
  fnam: string_leafname_t;             {file name}
  id: sys_int_machine_t;               {module ID within this firmware}

label
  abort;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);

  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_ids.mdev'(0)); {set fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_vstring (buf, 'firmware '(0), -1); {write FIRMWARE command}
  string_append (buf, fw.name_p^);
  wbuf;
  if sys_error(stat) then goto abort;

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}
    string_vstring (buf, '  id '(0), -1); {start ID subcommand}
    string_append_intu (buf, id, 0);   {add ID}
    string_append1 (buf, ' ');
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add module name}
    wbuf;                              {write the line}
    if sys_error(stat) then goto abort;
    end;

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
