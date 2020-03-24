{   Program MDEVBUILD
}
program mdevbuild;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'hier.ins.pas';
%include 'mdev.ins.pas';

var
  fw:                                  {target firmware name}
    %include '(cog)lib/string32.ins.pas';
  md: mdev_t;                          {MDEV library state}
  tk:                                  {scratch token}
    %include '(cog)lib/string32.ins.pas';
  fw_p: mdev_fw_p_t;                   {pointer to the firmware being built}

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
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-FW',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -FW fwname
}
1: begin
  string_cmline_token (fw, stat);
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
  if fw.len <= 0 then begin            {no firmware name explicitly given ?}
    sys_envvar_get (                   {read the FWNAME environment variable}
      string_v('FWNAME'(0)),           {variable name}
      tk,                              {returned value}
      stat);
    if sys_error(stat)
      then begin                       {didn't get envvar value}
        fw.len := 0;
        end
      else begin                       {envvar value is in TK}
        string_copy (tk, fw);          {copy value to firmware name}
        end
      ;
    end;

  mdev_lib_start (md, util_top_mem_context); {start use of the MDEV library}
  mdev_read_dirs (                     {read MDEV file set}
    md,                                {MDEV library state}
    string_v('.'),                     {start in current directory}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  mdev_resolve (md);                   {resolve dependencies, add modules to FWs}

  if fw.len <= 0 then begin            {firmware name still not set ?}
    if                                 {exactly one firmware in MDEV data ?}
        (md.fw_p <> nil) and then      {at least one firmware ?}
        (md.fw_p^.next_p = nil)        {no second firmware ?}
        then begin
      string_copy (md.fw_p^.fw_p^.name_p^, fw); {get name of the single firmware}
      end;
    end;

  if fw.len <= 0 then begin            {no firmware name given or implied ?}
    sys_message_bomb ('mdev', 'nofwname', nil, 0);
    end;

  mdev_fw_find (                       {find the target FW in the MDEV data}
    md,                                {MDEV data top descriptor}
    fw,                                {firmware name}
    true,                              {create blank if not existing}
    fw_p);                             {returned pointer to the firmware}

  mdev_show_fw (fw_p^);                {show details of this firmware}

  mdev_lib_end (md);                   {end use of the MDEV library}
  end.
