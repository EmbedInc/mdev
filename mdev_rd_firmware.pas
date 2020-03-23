module mdev_rd_firmware;
define mdev_rd_firmware;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine IMPLEMENTS (MD, IFACE, FW)
*
*   The firmware FW implements the interface IFACE.  Make sure all data
*   structures indicate this.
}
procedure implements (                 {make iface as implement by a firmware}
  in out  md: mdev_t;                  {library use state}
  in out  iface: mdev_iface_t;         {the interface}
  in out  fw: mdev_fw_t);              {the firmware that implements the interface}
  val_param; internal;

var
  fwent_p: mdev_fw_ent_p_t;            {firmwares list entry}
  ifent_p: mdev_iface_ent_p_t;         {interfaces list entry}

label
  done_iface, done_fw;

begin
{
*   Update the interface descriptor, if needed.
}
  fwent_p := iface.fw_p;               {init to first firmware in implements list}
  while fwent_p <> nil do begin        {back here each new list entry}
    if fwent_p^.fw_p = addr(fw)        {this firmware already in list ?}
      then goto done_iface;
    fwent_p := fwent_p^.next_p;        {to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {alloc mem for new list entry}
    sizeof(fwent_p^), md.mem_p^, false, fwent_p);
  fwent_p^.fw_p := addr(fw);           {fill in the list entry}
  fwent_p^.next_p := iface.fw_p;       {link new entry to start of list}
  iface.fw_p := fwent_p;

done_iface:                            {done updating the interface}
{
*   Update the firmware descriptor, if needed.
}
  ifent_p := fw.impl_p;                {init to first interface in implemented list}
  while ifent_p <> nil do begin        {back here each new list entry}
    if ifent_p^.iface_p = addr(iface)  {this interface already in list ?}
      then goto done_fw;
    ifent_p := ifent_p^.next_p;        {to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {alloc mem for new list entry}
    sizeof(ifent_p^), md.mem_p^, false, ifent_p);
  ifent_p^.iface_p := addr(iface);     {fill in the list entry}
  ifent_p^.shared := false;
  ifent_p^.next_p := fw.impl_p;        {link new entry to start of list}
  fw.impl_p := ifent_p;

done_fw:
  end;
{
********************************************************************************
*
*   Local subroutine READ_ID (MR, FW, STAT)
*
*   Read the remainder of the ID subcommand.  The command name has been read.
*   STAT is assumed to be initialized to no error by the caller.
}
procedure read_id (                    {read ID subcommand}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  fw: mdev_fw_t;               {the firmware this subcommand is for}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  id: sys_int_machine_t;               {module ID}
  name: string_var32_t;                {module name}
  ent_p: mdev_mod_ent_p_t;             {modules list entry for this module}
  mod_p: mdev_mod_p_t;                 {pointer to this module}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

begin
  name.max := size_char(name.str);     {init local var string}

  hier_read_int (mr.rd, id, stat);     {read the module ID}
  if sys_error(stat) then return;
  if                                   {ID is out of range ?}
      (id < mdev_modid_min_k) or
      (id > mdev_modid_max_k)
      then begin
    sys_stat_set (mdev_subsys_k, mdev_stat_badid_k, stat); {bad ID}
    hier_err_line_file (mr.rd, stat);  {add line number and file name}
    return;
    end;

  if not hier_read_tk_req (mr.rd, name, stat) {read the module name}
    then return;

  if not hier_read_eol (mr.rd, stat)   {not at end of line ?}
    then return;
{
*   The command has been read and verified.  The following state is set:
*
*     ID  -  Module ID, has been range checked.
*
*     NAME  -  Module name.
}
  mdev_mod_get (mr.md_p^, name, ent_p); {get modules list entry for this module}
  mod_p := ent_p^.mod_p;               {get pointer to the module}
  {
  *   Check to make sure this ID hasn't already been assigned to a different
  *   module.
  }
  if fw.modids[id] <> nil then begin   {some module already assigned this ID ?}
    if fw.modids[id] = mod_p
      then begin                       {already assigned to the target module ?}
        return;                        {everything as desired, nothing to do}
        end
      else begin                       {ID previously assigned to different module}
        sys_stat_set (mdev_subsys_k, mdev_stat_idused_k, stat); {ID previously used}
        sys_stat_parm_int (id, stat);  {module ID}
        sys_stat_parm_vstr (fw.modids[id]^.name_p^, stat); {module name}
        hier_err_line_file (mr.rd, stat); {add line number and file name}
        return;
        end
      ;
    end;
  {
  *   Check to make sure this module hasn't already been assigned a different ID
  *   within this firmware.
  }
  for ii := mdev_modid_min_k to mdev_modid_max_k do begin {scan module IDs this FW}
    if ii = id then next;              {duplicate of the same ID is OK}
    if fw.modids[ii] = mod_p then begin {this module already has different ID ?}
      sys_stat_set (mdev_subsys_k, mdev_stat_dupid_k, stat); {duplicate ID}
      sys_stat_parm_int (ii, stat);    {previous ID}
      hier_err_line_file (mr.rd, stat); {add line number and file name}
      return;
      end;
    end;                               {back to check next ID}
  {
  *   Assign the ID.
  }
  fw.modids[id] := mod_p;              {assign the ID to this module}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_RD_FIRMWARE (MR, STAT)
*
*   Read the remainder of the FIRMWARE command.  The command name has been read.
*   STAT is assumed to be initialized to no error by the caller.
}
procedure mdev_rd_firmware (           {read FIRMWARE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

var
  tk: string_var32_t;                  {token read from input line}
  name: string_var8192_t;              {firmware name with hierarchy}
  ent_p: mdev_fw_ent_p_t;              {pointer to new interface list entry}
  obj_p: mdev_fw_p_t;                  {pointer to new interface object}
  ifent_p: mdev_iface_ent_p_t;         {pointer to global interfaces list entry}

begin
  tk.max := size_char(tk.str);         {init local var strings}
  name.max := size_char(name.str);

  name.len := 0;                       {init firmware name to empty}
  while hier_read_tk (mr.rd, tk) do begin {read each hierarchy name}
    string_append_token (name, tk);    {add this name to hierarchy}
    end;
  if name.len <= 0 then begin          {no firmware name at all ?}
    hier_err_missing (mr.rd, stat);
    return;
    end;

  mdev_fw_get (mr.md_p^, name, ent_p); {find global list entry}
  obj_p := ent_p^.fw_p;                {get pointer to the object itself}

  hier_read_block_start (mr.rd);       {enter the subordinate block}
  while hier_read_line (mr.rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (mr.rd,
        'PROVIDES ID',
        stat) of

1:    begin                            {PROVIDES iface}
        if not hier_read_tk_req (mr.rd, tk, stat) {get interface name into TK}
          then return;
        if not hier_read_eol (mr.rd, stat) then return;

        mdev_iface_get (mr.md_p^, tk, ifent_p); {get pointer to interface list entry}
        implements (                   {mark interface as implemented by this FW}
          mr.md_p^, ifent_p^.iface_p^, obj_p^);
        end;

2:    begin                            {ID id modname}
        read_id (mr, obj_p^, stat);    {read and process the ID subcommand}
        end;

otherwise
      return;                          {bad or no keyword, STAT already set}
      end;
    if sys_error(stat) then return;
    end;                               {back for next subcommand}
  end;
