module mdev_wr_mod_hier;
define mdev_wr_mod_hier;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine WRITE_MOD_DEPENDS (WR, MOD1, MOD2, STAT)
*
*   Write if module MOD1 depends on module MOD2.  If MOD1 does not depend on
*   MOD2, then nothing is written.  Otherwise, one line is written to indicate
*   the dependency.  This line also indicates whether the use of MOD2 can be
*   shared with other modules.
}
procedure write_mod_depends (          {write MOD1 depends on MOD2, if it does}
  in out  wr: hier_write_t;            {output file writing state}
  in      mod1, mod2: mdev_mod_t;      {MOD1 might depend on MOD2}
  out     stat: sys_err_t);
  val_param; internal;

var
  if1_p: mdev_iface_ent_p_t;           {MOD1 required interfaces list entry}
  if2_p: mdev_iface_ent_p_t;           {MOD2 exported interfaces list entry}
  dep: boolean;                        {MOD1 depends on MOD2}
  shared: boolean;                     {MOD2 can be shared with others}

label
  have_dep;

begin
  sys_error_none (stat);               {init to no error}

  dep := false;                        {init to MOD1 not dependent on MOD2}
  shared := false;                     {init to MOD1 needs exclusive access to MOD2}

  if1_p := mod1.uses_p;                {loop over interfaces required by MOD1}
  while if1_p <> nil do begin
    if2_p := mod2.impl_p;              {loop over interfaces provided by MOD2}
    while if2_p <> nil do begin
      if if2_p^.iface_p = if1_p^.iface_p then begin {found dependency ?}
        dep := true;                   {flag that dependency was found}
        if not if1_p^.shared then goto have_dep; {needs exclusive access to MOD2 ?}
        end;
      if2_p := if2_p^.next_p;          {to next MOD2 exported interface}
      end;
    if1_p := if1_p^.next_p;            {to next MOD1 required interface}
    end;

  shared := true;                      {MOD2, if used at all, can be shared}

have_dep:                              {DEP and SHARED all set}
  if dep then begin                    {dependency exists ?}
    hier_write_str (wr, 'new Tuple<string, string, bool>("');
    hier_write_vstr (wr, mod1.name_p^); {module name}
    hier_write_str (wr, '", "');
    hier_write_vstr (wr, mod2.name_p^); {name of module dependent on}
    hier_write_str (wr, '", ');
    if shared
      then hier_write_str (wr, 'false')
      else hier_write_str (wr, 'true');
    hier_write_str (wr, '),');
    hier_write_line (wr, stat);
    end;
  end;
{
********************************************************************************
*
*   Local subroutine WRITE_MOD_EXLUSIVE (WR, MOD1, MOD2, STAT)
*
*   Write a line to the output file if the two modules are mutually exclusive of
*   each other.  That means they both depend on the same interface, but that
*   interface can not be shared by both modules.  Nothing is written if the two
*   modules have no conflict.
}
procedure write_mod_exclusive (        {write if MOD1 and MOD2 are mutually exclusive}
  in out  wr: hier_write_t;            {output file writing state}
  in      mod1, mod2: mdev_mod_t;      {MOD1 might depend on MOD2}
  out     stat: sys_err_t);
  val_param; internal;

var
  if1_p: mdev_iface_ent_p_t;           {MOD1 required interfaces list entry}
  if2_p: mdev_iface_ent_p_t;           {MOD2 required interfaces list entry}

label
  next2, excl;

begin
  sys_error_none (stat);               {init to no error}
  if1_p := mod1.uses_p;
  while if1_p <> nil do begin          {scan list of interfaces used by module 1}
    if2_p := mod2.uses_p;
    while if2_p <> nil do begin        {scan list of interfaces used by module 2}
      if if2_p^.iface_p <> if1_p^.iface_p then goto next2; {not same interface ?}
      if                               {check for conflict using this interface}
          (not if1_p^.shared) or       {module 1 can't share this interface ?}
          (not if2_p^.shared)          {module 2 can't share this interface ?}
          then begin
        goto excl;                     {go show these modules can't coexist}
        end;
next2:                                 {advance to next interface used by module 2}
      if2_p := if2_p^.next_p;          {to next module 2 interface list entry}
      end;                             {back to test against this new interface}
    if1_p := if1_p^.next_p;            {to next module 1 interface list entry}
    end;                               {back to test against this new interface}

  return;                              {the two modules don't conflict}
{
*   The two modules are mutually exclusive.  Write an output line naming these
*   two module.
}
excl:
  hier_write_str (wr, 'new Tuple<string, string>("');
  hier_write_vstr (wr, mod1.name_p^);  {module name}
  hier_write_str (wr, '", "');
  hier_write_vstr (wr, mod2.name_p^);  {name of module dependent on}
  hier_write_str (wr, '"),');
  hier_write_line (wr, stat);
  end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_MOD_HIER (FW, VERBOSE, STAT)
*
*   Write the fwname_DEPS.CS file, which defines the dependency hierarch of the
*   MDEV modules in this firmware.  This file is intended to be imported into
*   MetriConnect so that it can perform dependency checking and validation.
}
procedure mdev_wr_mod_hier (           {write modules hierarchy to fwname_DEPS.CS file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  wr: hier_write_t;                    {file writing state}
  tk: string_var132_t;                 {scratch token}
  mod_p: mdev_mod_ent_p_t;             {pointer to current module in list}
  mod2_p: mdev_mod_ent_p_t;            {pointer to second module to compare first to}
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  abort;

begin
  tk.max := size_char(tk.str);         {init local var string}

  string_copy (fw.name_p^, tk);        {init file name with firmware name}
  string_appends (tk, '_deps.cs'(0));  {add fixed part of file name}
  hier_write_file_open (               {open output file}
    tk, '',                            {file name}
    wr,                                {returned writing state}
    stat);
  if sys_error(stat) then return;
{
*   Write header comments.
}
  hier_write_str (wr, '//   ');
  string_copy (fw.name_p^, tk);        {make upper case firmware name}
  string_upcase (tk);
  hier_write_vstr (wr, tk);
  hier_write_str (wr, ' firmware MDEV module hierarchy.');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, '//');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
{
*   Write contents.
}
  hier_write_str (wr, 'using System;');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;

  hier_write_str (wr, 'namespace Jowa.MdevIds {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  hier_write_str (wr, 'public class ');
  hier_write_vstr (wr, fw.name_p^);
  hier_write_str (wr, '_Definitions : Definitions_Base {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  hier_write_str (wr, 'public override string[] Modules => new string[] {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  {
  *   Write list of modules in this firmware.
  }
  mod_p := fw.mod_p;                   {init to first module in list}
  while mod_p <> nil do begin          {scan the list}
    hier_write_str (wr, '"');
    hier_write_vstr (wr, mod_p^.mod_p^.name_p^); {write name of this module}
    hier_write_str (wr, '",');
    hier_write_line (wr, stat); if sys_error(stat) then goto abort;
    mod_p := mod_p^.next_p;            {to next module in list}
    end;                               {back to process this next module}

  hier_write_str (wr, '};');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);
  {
  *   For each module, list the modules it depends on, if any.  In this section
  *   MOD1 is the module for which dependencies are listed, and MOD2 is a
  *   candidate module that MOD1 might depend on.
  }
  hier_write_str (wr, 'public override Tuple<string, string, bool>[] ');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_block_start (wr);
  hier_write_str (wr, 'Dependencies => new Tuple<string, string, bool>[] {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  mod_p := fw.mod_p;                   {loop over all the modules in this firmware}
  while mod_p <> nil do begin
    mod2_p := fw.mod_p;                {scan all the modules that MOD1 might depend on}
    while mod2_p <> nil do begin
      if mod2_p^.mod_p <> mod_p^.mod_p then begin {not self ?}
        write_mod_depends (            {show if MOD1 depends on MOD1}
          wr, mod_p^.mod_p^, mod2_p^.mod_p^, stat);
        if sys_error(stat) then goto abort;
        end;
      mod2_p := mod2_p^.next_p;        {to next candidate dependency module}
      end;
    mod_p := mod_p^.next_p;            {to next module to write dependencies of}
    end;

  hier_write_str (wr, '};');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);
  {
  *   Write list of mutually exclusive modules.  These are pairs of modules that
  *   use the same interface, but can not share that interface.
  }
  hier_write_str (wr, 'public override Tuple<string, string>[]');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_block_start (wr);
  hier_write_str (wr, 'Exclusions => new Tuple<string, string>[] {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);

  mod_p := fw.mod_p;                   {loop over all the modules in this firmware}
  while mod_p <> nil do begin
    mod2_p := mod_p^.next_p;           {scan all following modules in the list}
    while mod2_p <> nil do begin
      write_mod_exclusive (            {write entry if modules mutually exclusive}
        wr, mod_p^.mod_p^, mod2_p^.mod_p^, stat);
      if sys_error(stat) then goto abort;
      mod2_p := mod2_p^.next_p;        {to next "other" module to check against}
      end;
    mod_p := mod_p^.next_p;            {to next module to check exclusions with}
    end;

  hier_write_str (wr, '};');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);
{
*   Done writing output file contents.
}
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
