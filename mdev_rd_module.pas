module mdev_rd_module;
define mdev_rd_module;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine MOD_USES (MR, MOD, STAT)
}
procedure mod_uses (                   {process USES command after the keyword}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  mod: mdev_mod_t;             {the module}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  name: string_var32_t;                {interface name}
  shared: boolean;                     {this use can share the interface}
  ent_p: mdev_iface_ent_p_t;           {pointer to interfaces list entry}
  obj_p: mdev_iface_p_t;               {pointer to interface descriptor}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (mr.rd, name, stat) then return; {get interface name}
  case hier_read_keyw_pick (mr.rd, 'SHARED', stat) of {check for "SHARED"}
-1: begin                              {nothing after interface name}
      shared := false;
      sys_error_none (stat);           {no keyword is allowed}
      end;
1:  begin                              {SHARED}
      shared := true;
      if not hier_read_eol (mr.rd, stat) then return;
      end;
otherwise
    return;
    end;

  mdev_iface_get (mr.md_p^, name, ent_p); {find list entry for this interface}
  obj_p := ent_p^.iface_p;             {get pointer to interface descriptor}

  ent_p := mod.uses_p;                 {init to first USES list entry}
  while ent_p <> nil do begin          {scan the existing USES entries}
    if ent_p^.iface_p = obj_p then begin {found existing list entry ?}
      if ent_p^.shared = shared then return; {all is in order ?}
      sys_stat_set (mdev_subsys_k, mdev_stat_share_k, stat); {sharing inconsistancy}
      sys_stat_parm_vstr (mod.name_p^, stat); {module name}
      sys_stat_parm_vstr (obj_p^.name_p^, stat); {interface name}
      hier_err_line_file (mr.rd, stat); {add line number and file name}
      return;                          {sharing inconsistancy error}
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {allocate mem for new USES list entry}
    sizeof(ent_p^), mr.md_p^.mem_p^, false, ent_p);
  ent_p^.iface_p := obj_p;             {fill in list entry}
  ent_p^.shared := shared;
  ent_p^.next_p := mod.uses_p;         {link to entry to start of list}
  mod.uses_p := ent_p;
  end;
{
********************************************************************************
*
*   Local subroutine MOD_PROV (MR, STAT)
}
procedure mod_prov (                   {process PROVIDES command after the keyword}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  mod: mdev_mod_t;             {the module}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  name: string_var32_t;                {interface name}
  ent_p: mdev_iface_ent_p_t;           {pointer to interfaces list entry}
  obj_p: mdev_iface_p_t;               {pointer to interface descriptor}
  modent_p: mdev_mod_ent_p_t;          {pointer to implementing modules list entry}

label
  done_mod, done_iface;

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (mr.rd, name, stat) then return; {get interface name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_iface_get (mr.md_p^, name, ent_p); {find list entry for this interface}
  obj_p := ent_p^.iface_p;             {get pointer to interface descriptor}

  ent_p := mod.impl_p;                 {init to first IMPLEMENTS list entry}
  while ent_p <> nil do begin          {scan the existing list entries}
    if ent_p^.iface_p = obj_p          {this interface is already listed ?}
      then goto done_mod;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {allocate mem for new IMPLEMENTS list entry}
    sizeof(ent_p^), mr.md_p^.mem_p^, false, ent_p);
  ent_p^.iface_p := obj_p;             {fill in list entry}
  ent_p^.shared := false;
  ent_p^.next_p := mod.impl_p;         {link to entry to start of list}
  mod.impl_p := ent_p;

done_mod:                              {done updating module}
{
*   Make sure this module is listed in the module as implementing it.  OBJ_P is
*   pointing to the interface being implemented.
}
  modent_p := obj_p^.impl_p;           {init to first list entry}
  while modent_p <> nil do begin       {back here each new list entry}
    if modent_p^.mod_p = addr(mod)     {this module is already listed ?}
      then goto done_iface;
    modent_p := modent_p^.next_p;      {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {alloc mem for implementing modules list entry}
    sizeof(modent_p^), mr.md_p^.mem_p^, false, modent_p);
  modent_p^.mod_p := addr(mod);        {fill in the list entry}
  modent_p^.next_p := obj_p^.impl_p;   {link to start of implementing modules list}
  obj_p^.impl_p := modent_p;

done_iface:                            {done updating interface}
  end;
{
********************************************************************************
*
*   Local subroutine MOD_TEMPL (MR, STAT)
}
procedure mod_templ (                  {process TEMPLATE command after the keyword}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  mod: mdev_mod_t;             {the module}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  name: string_treename_t;             {file name from command line}
  ent_p: mdev_file_ent_p_t;            {pointer to files list entry}
  obj_p: mdev_file_p_t;                {pointer to file descriptor}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (mr.rd, name, stat) then return; {get file name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_file_get (mr.md_p^, name, ent_p); {find list entry for this file}
  obj_p := ent_p^.file_p;              {get pointer to file descriptor}

  ent_p := mod.templ_p;                {init to first templates list entry}
  while ent_p <> nil do begin          {scan the existing list entries}
    if ent_p^.file_p = obj_p then return; {this file is already listed ?}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), mr.md_p^.mem_p^, false, ent_p);
  ent_p^.file_p := obj_p;              {fill in list entry}
  ent_p^.next_p := mod.templ_p;        {link to entry to start of list}
  mod.templ_p := ent_p;
  end;
{
********************************************************************************
*
*   Local subroutine MOD_SOURCE (MR, STAT)
}
procedure mod_source (                 {process SOURCE command after the keyword}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  mod: mdev_mod_t;             {the module}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  name: string_treename_t;             {file name from command line}
  ent_p: mdev_file_ent_p_t;            {pointer to files list entry}
  obj_p: mdev_file_p_t;                {pointer to file descriptor}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (mr.rd, name, stat) then return; {get file name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_file_get (mr.md_p^, name, ent_p); {find list entry for this file}
  obj_p := ent_p^.file_p;              {get pointer to file descriptor}

  ent_p := mod.files_p;                {init to first files list entry}
  while ent_p <> nil do begin          {scan the existing list entries}
    if ent_p^.file_p = obj_p then return; {this file is already listed ?}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), mr.md_p^.mem_p^, false, ent_p);
  ent_p^.file_p := obj_p;              {fill in list entry}
  ent_p^.next_p := mod.files_p;        {link to entry to start of list}
  mod.files_p := ent_p;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_RD_MODULE (MR, STAT)
*
*   Read the remainder of the MODULE command.  The command name has been read.
*   STAT is assumed to be initialized to no error by the caller.
}
procedure mdev_rd_module (             {read MODULE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

var
  tk: string_var8192_t;                {token read from current input line}
  ent_p: mdev_mod_ent_p_t;             {pointer to module's list entry}
  obj_p: mdev_mod_p_t;                 {pointer to the module descriptor}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not hier_read_tk_req (mr.rd, tk, stat) then return; {get module name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_mod_get (mr.md_p^, tk, ent_p);  {get pointer to global list entry}
  obj_p := ent_p^.mod_p;               {get pointer to module descriptor}

  hier_read_block_start (mr.rd);       {go down into MODULE block}
  while hier_read_line (mr.rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (mr.rd,   {get subcommand keyword, pick from list}
        'DESC USES PROVIDES TEMPLATE SOURCE',
        stat) of

1:    begin                            {DESC}
        if not hier_read_eol (mr.rd, stat) then return;
        mdev_rd_text (mr, obj_p^.desc_p); {read descriptive text}
        end;

2:    begin                            {USES}
        mod_uses (mr, obj_p^, stat);   {process rest of command line}
        end;

3:    begin                            {PROVIDES}
        mod_prov (mr, obj_p^, stat);   {process rest of command line}
        end;

4:    begin                            {TEMPLATE}
        mod_templ (mr, obj_p^, stat);  {process rest of command line}
        end;

5:    begin                            {SOURCE}
        mod_source (mr, obj_p^, stat); {process rest of command line}
        end;

      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
    end;                               {back to get next subcommand}
  end;
