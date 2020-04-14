{   Program MDEVBUILD
}
program mdevbuild;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'hier.ins.pas';
%include 'mdev.ins.pas';
%include 'builddate.ins.pas';

var
  fw:                                  {target firmware name}
    %include '(cog)lib/string8192.ins.pas';
  fwpath:                              {full pathname of the firmware being built}
    %include '(cog)lib/string8192.ins.pas';
  md: mdev_t;                          {MDEV library state}
  fw_p: mdev_fw_p_t;                   {pointer to the firmware being built}
  verbose: boolean;                    {show more actions on standard output}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  stat: sys_err_t;                     {completion status}

label
  next_opt, err_parm, done_opts;

begin
{
*   Initialize before reading the command line.
}
  string_cmline_init;                  {init for reading the command line}
  verbose := false;                    {init to normal output level}
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-FW -V',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -FW fwname
}
1: begin
  string_cmline_token (fw, stat);
  end;
{
*   -V
}
2: begin
  verbose := true;
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

done_opts:                             {done with all the command line options}
  if verbose then begin
    writeln ('Program MDEVBUILD, built on ', build_dtm_str);
    end;

  mdev_lib_start (md, util_top_mem_context); {start use of the MDEV library}
  mdev_read_dirs (                     {read MDEV file set}
    md,                                {MDEV library state}
    string_v('.'),                     {start in current directory}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  if not mdev_fw_name_make (md, fw, fwpath) then begin {make full firmware pathname}
    sys_message_bomb ('mdev', 'nofwname', nil, 0);
    end;

  mdev_resolve (md);                   {resolve dependencies, add modules to FWs}

  mdev_fw_find (                       {find the target FW in the MDEV data}
    md,                                {MDEV data top descriptor}
    fwpath,                            {firmware name}
    true,                              {create blank if not existing}
    fw_p);                             {returned pointer to the firmware}

  if verbose then begin
    writeln;
    mdev_show_fw (fw_p^);              {show details of this firmware}
    end;

  mdev_wr_templ_list (                 {write the files from templates as appropriate}
    fw_p^,                             {firmware descriptor}
    verbose,
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_build (                      {write BUILD_MDEVS script to build MDEV modules}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_ins_main (                   {write main MDEV include file}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_ins_init (                   {write include file for initializing MDEV modules}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_mlist (                      {edit the MLIST file to include all MDEV modules}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_ids (                        {write MDEV and H files for this FW with the assigned IDs}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_wr_ids_cs (                     {write CS file with info about this firmware}
    fw_p^,                             {firmware descriptor}
    verbose,                           {selects more verbose output}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_lib_end (md);                   {end use of the MDEV library}
  end.
