module mdev_wr_ins;
define mdev_wr_ins_main;
define mdev_wr_ins_init;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_INS_MAIN (FW, VERBOSE, STAT)
*
*   Write the fwname_MDEV.INS.DSPIC file.  This file contains definitions that
*   need to be global to the firmware FW.  It also references all the global
*   include files required by the MDEV modules.
}
procedure mdev_wr_ins_main (           {write main MDEV include file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line output buffer}
  fnam: string_treename_t;             {scratch file name}
  sdir: string_treename_t;             {source directory portable pathname}
  fent_p: mdev_file_ent_p_t;           {pointer to files list entry}
  id: sys_int_machine_t;               {module ID}

label
  abort;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);

  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_mdev.ins.dspic'(0)); {add fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;
{
*   Write the include commands.
}
  string_vstring (sdir, '(cog)source'(0), -1); {save top level source directory}

  fent_p := fw.incl_p;                 {init to first include file in list}
  while fent_p <> nil do begin         {scan the include files list}
    string_vstring (buf, '/include "'(0), -1); {init this output line}
    if string_fnam_within (fent_p^.file_p^.name_p^, sdir, fnam)
      then begin                       {FNAM is path within SOURCE directory}
        string_append (buf, sdir);     {use portable pathname for SOURCE dir}
        string_append1 (buf, '/');
        string_append (buf, fnam);     {add pathname within SOURCE dir}
        end
      else begin                       {FNAM is not within SOURCE directory}
        string_append (buf, fent_p^.file_p^.name_p^); {use full original pathname}
        end
      ;
    string_append1 (buf, '"');         {add closing quote after file name}
    wbuf;                              {write this line to the output file}
    if sys_error(stat) then goto abort;
    fent_p := fent_p^.next_p;          {to next include file list entry}
    end;                               {back to process this new entry}
{
*   Define the CFG_xxx constants.
}
  wbuf;                                {write blank line before constants}
  if sys_error(stat) then goto abort;

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if not fw.modids[id].used then next; {this ID not used in this firmware ?}
    string_vstring (buf, '/const cfg_'(0), -1); {init fixed part of line}
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add module name}
    string_appends (buf, ' integer = '(0));
    string_append_intu (buf, id, 0);   {add the ID}
    wbuf;                              {write this line to the output file}
    if sys_error(stat) then goto abort;
    end;                               {back to do next ID}

abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
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

begin
 sys_error_none (stat);                {init to no errors encountered}
 end;
