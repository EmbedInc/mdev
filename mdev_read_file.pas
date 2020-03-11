module mdev_read_file;
define mdev_read_file;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine MDEV_RD_MDEVDIR (MR, STAT)
*
*   Process a MDEVDIR command.  The command name has been read.
}
procedure mdev_rd_mdevdir (            {read MDEVDIR command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  dir: string_treename_t;              {directory name}
  ent_p: mdev_dir_ent_p_t;             {pointer to global dir list entry}

begin
  dir.max := size_char(dir.str);       {init local var string}

  if not hier_read_tk (mr.rd, dir) then begin {not get directory name ?}
    hier_err_missing (mr.rd, stat);
    return;
    end;
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_dir_get (mr.md_p^, dir, ent_p); {make sure dir is in global list}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_READ_FILE (MD, FNAM, STAT)
*
*   Read the contents of the MDEV file FNAM, and add any new information to the
*   MDEV library use state MD.
}
procedure mdev_read_file (             {read one MDEV file}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      fnam: univ string_var_arg_t; {name of file to read, ".mdev" assumed}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  mr: mdev_read_t;                     {MDEV file reading state}
  stat2: sys_err_t;                    {second error, to avoid corrupting STAT}

label
  leave;

begin
  hier_read_open (                     {open file for hierarchical reading}
    fnam, '.mdev', mr.rd, stat);
  if sys_error(stat) then return;

  mr.md_p := addr(md);                 {fill in rest of MDEV file reading state}

  while hier_read_line (mr.rd, stat) do begin {loop over the top level commands}
    case hier_read_keyw_pick (mr.rd,   {get keyword, pick from list}
      'MDEVDIR INTERFACE FIRMWARE MODULE FILE',
      stat) of

1:    begin                            {MDEVDIR}
        mdev_rd_mdevdir (mr, stat);
        end;

2:    begin                            {INTERFACE}
        mdev_rd_interface (mr, stat);
        end;

3:    begin                            {FIRMWARE}
        mdev_rd_firmware (mr, stat);
        end;

4:    begin                            {MODULE}
        mdev_rd_module (mr, stat);
        end;

5:    begin                            {FILE}
        mdev_rd_file (mr, stat);
        end;

      end;                             {end of command cases}
    if sys_error(stat) then goto leave;
    end;                               {back for next line from MDEV file}

leave:                                 {file open, STAT already set}
  if sys_error(stat)
    then begin                         {error already encountered}
      hier_read_close (mr.rd, stat2);
      end
    else begin                         {no error so far}
      hier_read_close (mr.rd, stat);
      end
    ;
  end;
