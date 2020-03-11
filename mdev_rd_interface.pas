module mdev_rd_interface;
define mdev_rd_interface;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_RD_INTERFACE (MR, STAT)
*
*   Read the remainder of the INTERFACE command.  The command name has been
*   read.  STAT is assumed to be initialized to no error by the caller.
}
procedure mdev_rd_interface (          {read INTERFACE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

var
  name: string_var32_t;                {interface name}
  ent_p: mdev_iface_ent_p_t;           {pointer to new interface list entry}
  obj_p: mdev_iface_p_t;               {pointer to new interface object}

begin
  name.max := size_char(name.str);     {init local var string}

  if not hier_read_tk_req (mr.rd, name, stat) then return; {get name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_iface_get (mr.md_p^, name, ent_p); {find global list entry}
  obj_p := ent_p^.iface_p;             {get pointer to the object itself}

  hier_read_block_start (mr.rd);       {enter the subordinate block}
  while hier_read_line (mr.rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (mr.rd,
        'DESC',
        stat) of

1:    begin                            {DESC}
        if not hier_read_eol (mr.rd, stat) then return;
        mdev_rd_text (mr, obj_p^.desc_p); {read descriptive text}
        end;

otherwise
      return;                          {bad or no keyword, STAT already set}
      end;
    end;                               {back for next subcommand}
  end;
