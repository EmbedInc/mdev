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
*   Subroutine MDEV_WR_MOD_HIER (FW, VERBOSE, STAT)
*
*   Write the ModHier.cs file, which defines the dependency hierarch of the MDEV
*   modules in this firmware.  This file is intended to be imported into
*   MetriConnect so that it can perform dependency checking and validation.
}
procedure mdev_wr_mod_hier (           {write modules hierarchy to ModHier.cs file}
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

  string_vstring (tk, 'ModHier.cs'(0), -1); {make output file name}
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

  hier_write_str (wr, '//   Written ');
  sys_clock_str1 (sys_clock, tk);      {make current date/time string}
  hier_write_vstr (wr, tk);
  hier_write_str (wr, '.');
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

  hier_write_str (wr, 'internal static class Definitions {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);

  hier_write_str (wr, 'public static string[] Modules = new string[] {');
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

  hier_write_str (wr, 'public static Tuple<string, string, bool>[] ');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_start (wr);
  hier_write_block_start (wr);
  hier_write_str (wr, 'Dependencies = new Tuple<string, string, bool>[] {');
  hier_write_line (wr, stat); if sys_error(stat) then goto abort;
  hier_write_block_end (wr);
  {
  *   For each module, list the modules it depends on, if any.  In this section
  *   MOD1 is the module for which dependencies are listed, and MOD2 is a
  *   candidate module that MOD1 might depend on.
  }
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
