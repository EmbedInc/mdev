module mdev_wr_ids;
define mdev_wr_ids;
define mdev_wr_ids_cs;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_IDS (FW, VERBOSE, STAT)
*
*   Write the files that define the MDEV module IDs.  These are:
*
*     <fwname>_IDS.MDEV
*
*       Will be used as input for MDEV build programs.  Keeping this file around
*       is how MDEV IDs are remembered once initially assigned.
*
*     <fwname>_IDS.H
*
*       C language include file.
*
*     <fwname>_IDS.INS.PAS
*
*       Pascal language include file.
}
procedure mdev_wr_ids (                {write files that define MDEV IDs, various languages}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the file being written}
  buf: string_var1024_t;               {one line output buffer}
  fnam: string_leafname_t;             {file name}
  tk: string_var1024_t;                {scratch token}
  id: sys_int_machine_t;               {module ID within this firmware}
  first: boolean;                      {processing the first ID}

label
  abort;

%include 'wbuf_local.ins.pas';

begin
  buf.max := size_char(buf.str);       {init local var string}
  fnam.max := size_char(fnam.str);
  tk.max := size_char(tk.str);
{
*   Write the fwname_IDS.MDEV file.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_ids.mdev'(0)); {add fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_vstring (buf, 'firmware '(0), -1); {write FIRMWARE command}
  mdev_fw_name_path (fw, tk);          {get firmware full pathname}
  string_append (buf, tk);
  wbuf (stat);
  if sys_error(stat) then goto abort;

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    string_vstring (buf, '  id '(0), -1); {start ID subcommand}
    string_append_intu (buf, id, 0);   {add ID}
    string_append1 (buf, ' ');
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add module name}
    wbuf (stat);                       {write the line}
    if sys_error(stat) then goto abort;
    end;

  file_close (conn);                   {close the file}
{
*   Write the fwname_IDS.H file.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_ids.h'(0));  {add fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_vstring (buf, '//   firmware "'(0), -1); {init header comment}
  mdev_fw_name_path (fw, tk);          {get firmware full pathname}
  string_append (buf, tk);
  string_append1 (buf, '"');
  wbuf (stat);
  if sys_error(stat) then goto abort;

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}
    string_vstring (buf, '#define CFG_'(0), -1);
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add module name}
    string_appends (buf, ' ('(0));
    string_append_intu (buf, id, 0);   {add ID}
    string_append1 (buf, ')');
    wbuf (stat);                       {write the line}
    if sys_error(stat) then goto abort;
    end;

  file_close (conn);                   {close the file}
{
*   Write the fwname_IDS.INS.PAS file.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_ids.ins.pas'(0)); {add fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_vstring (buf, '{   Mdev module IDs for firmware '(0), -1); {init header comment}
  mdev_fw_name_path (fw, tk);          {get firmware full pathname}
  string_upcase (tk);
  string_append (buf, tk);
  string_appends (buf, '.'(0));
  wbuf (stat);
  if sys_error(stat) then goto abort;
  string_vstring (buf, '}'(0), -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;

  first := true;                       {next ID will be the first in the list}
  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}
    if first then begin                {write header before first ID ?}
      first := false;                  {next ID won't be the first anymore}
      string_vstring (buf, 'const'(0), -1);
      wbuf (stat);
      if sys_error(stat) then goto abort;
      end;
    string_vstring (buf, '  mdevid_'(0), -1);
    string_append (buf, fw.name_p^);
    string_append1 (buf, '_');
    string_append (buf, fw.modids[id].mod_p^.name_p^); {add module name}
    string_appends (buf, '_k = '(0));
    string_append_intu (buf, id, 0);   {add ID}
    string_append1 (buf, ';');
    wbuf (stat);                       {write the line}
    if sys_error(stat) then goto abort;
    end;

  file_close (conn);                   {close the file}
{
*   Write the fwname_SUBSYS_STR.INS.PAS file.
}
  string_copy (fw.name_p^, fnam);      {init file name with the firmware name}
  string_appends (fnam, '_subsys_str.ins.pas'(0)); {add fixed part of the file name}

  file_open_write_text (               {open the file}
    fnam, '',                          {file name and suffix}
    conn,                              {returned connection to the file}
    stat);
  if sys_error(stat) then return;

  string_vstring (buf, '  {'(0), -1);  {section comment}
  wbuf (stat);
  if sys_error(stat) then goto abort;
  string_vstring (buf,
    '  *   Set NAME to name of subsystem with id ID.  Empty string when ID unknown.',
    -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;
  string_vstring (buf, '  }'(0), -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;

  string_vstring (buf, '  case id of'(0), -1); {start the CASE statement}
  wbuf (stat);
  if sys_error(stat) then goto abort;

  string_vstring (buf, '    0: string_vstring (name, ''System''(0), -1);'(0), -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}

    string_appends (buf, '    '(0));
    string_append_intu (buf, id, 0);
    string_appends (buf, ': string_vstring (name, '''(0));
    string_append (buf, fw.modids[id].mod_p^.name_p^);
    string_appends (buf, '''(0), -1);'(0));
    wbuf (stat);                       {write the line}
    if sys_error(stat) then goto abort;
    end;

  string_vstring (buf, '    otherwise'(0), -1); {start OTHERWISE clause}
  wbuf (stat);
  if sys_error(stat) then goto abort;
  string_vstring (buf, '      name.len := 0;'(0), -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;
  string_vstring (buf, '    end;'(0), -1);
  wbuf (stat);
  if sys_error(stat) then goto abort;

  file_close (conn);                   {close the file}
{
*   All done.  Normal exit point.
}
  return;
{
*   Error exit.  Jump here on error when a output file is open.  STAT must
*   already be set to indicate the error.
}
abort:                                 {file open, STAT all set}
  file_close (conn);                   {close the file}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_IDS_CS (FW, VERBOSE, STAT)
*
*   Write the fwname_IDS.CS file.  This file provides information about this
*   firmware to host programs written in C#.
}
procedure mdev_wr_ids_cs (             {write MDEV file with assigned module IDs}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  wr: hier_write_t;                    {file writing state}
  tk: string_var132_t;                 {scratch token}
  id: sys_int_machine_t;               {module ID within this firmware}
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  abort;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_copy (fw.name_p^, tk);        {init file name with firmware name}
  string_appends (tk, '_ids.cs'(0));   {finish the file name}
  hier_write_file_open (               {open the output file for hierarchical writing}
    tk, '',                            {file name and suffix}
    wr,                                {returned file writing state}
    stat);
  if sys_error(stat) then return;

  hier_write_str (wr, 'using System;');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'using System.Linq;');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'namespace Jowa.MdevIds {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  hier_write_str (wr, 'class IDs_');
  hier_write_vstr (wr, fw.name_p^);
  hier_write_str (wr, ' : IDs_Base {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}
    hier_write_str (wr, 'public const int CFG_');
    hier_write_vstr (wr, fw.modids[id].mod_p^.name_p^);
    hier_write_str (wr, ' =');
    hier_write_int (wr, id);
    hier_write_str (wr, ';');
    hier_write_line (wr, stat); if sys_error(stat) then goto abort;
    end;

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'private static readonly Tuple<string, int>[] _ids = new Tuple<string, int>[] {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  for id := mdev_modid_min_k to mdev_modid_max_k do begin {scan all possible IDs}
    if fw.modids[id].mod_p = nil then next; {nothing assigned to this ID ?}
    if not fw.modids[id].used then next; {module assigned here not included in FW}
    hier_write_str (wr, 'new Tuple<string, int>("');
    hier_write_vstr (wr, fw.modids[id].mod_p^.name_p^);
    hier_write_str (wr, '", CFG_');
    hier_write_vstr (wr, fw.modids[id].mod_p^.name_p^);
    hier_write_str (wr, '),');
    hier_write_line (wr, stat); if sys_error(stat) then goto abort;
    end;

  hier_write_str (wr, '};');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'public override string FirmwareName => "');
  hier_write_vstr (wr, fw.name_p^);
  hier_write_str (wr, '";');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'public override int GetModuleId(string s)');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_str (wr, '=> (from u in _ids where u.Item1 == s select u.Item2).FirstOrDefault();');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'public override string GetModuleName(int n)');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_str (wr, '=> (from u in _ids where u.Item2 == n select u.Item1).FirstOrDefault();');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'public override int ModuleCount => _ids.Length;');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_blankline (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'public override Tuple<string, int> GetModuleEntry(int n)');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_str (wr, '=> new Tuple<string, int>(_ids[n].Item1, _ids[n].Item2);');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_str (wr, '}');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_str (wr, '}');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  hier_write_file_close (wr, stat);
  return;                              {normal return point}
{
*   Error exit.  Jump here on error when a output file is open.  STAT must
*   already be set to indicate the error.
}
abort:                                 {file open, STAT all set}
  hier_write_file_close (wr, stat2);
  end;
