module mdev_resolve;
define mdev_resolve;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_RESOLVE (MD)
*
*   Resolve dependencies, add modules to all firmwares as appropriate, and
*   assign IDs to the added modules.
*
*   A module is added to a firmware if all the requirements of that module are
*   met.  Requirements are either provided by the firmware directly or by other
*   modules added to that firmware.  Newly added module may satisfy requirements
*   of other modules, which may satisfy requirements of more modules, etc.  This
*   process is continued until there are no new modules that can be added with
*   the current set of interfaces provided.
*
*   Within each firmware, modules are assigned IDs in ascending order starting
*   with 1.  Modules only depend on interfaces provide by the firmware directly,
*   or by modules with lower assigned IDs.  One purpose of this is so that it is
*   safe to initialize modules when the firmware starts up in ID order.
*
*   Fixed IDs assigned in the MDEV files using the FIRMWARE > ID command can
*   cause exceptions to this rule.
}
procedure mdev_resolve (               {resolve dependencies, add modules to FWs}
  in out  md: mdev_t);                 {MDEV library use state}
  val_param;

var
  filent_p: mdev_file_ent_p_t;         {points to current files list entry}
  modent_p: mdev_mod_ent_p_t;          {points to current modules list entry}
  fwent_p: mdev_fw_ent_p_t;            {points to current firmwares list entry}

begin
  filent_p := md.file_p;               {init to first entry in files list}
  while filent_p <> nil do begin       {back here each new list entry}
    mdev_resolve_file (md, filent_p^.file_p^); {resolve dependencies of this file}
    filent_p := filent_p^.next_p;      {advance to next list entry}
    end;                               {back to do next list entry}

  modent_p := md.mod_p;                {init to first entry in modules list}
  while modent_p <> nil do begin       {back here each new list entry}
    mdev_resolve_mod (md, modent_p^.mod_p^); {resolve dependencies of this module}
    modent_p := modent_p^.next_p;      {advance to next list entry}
    end;                               {back to do next list entry}

  fwent_p := md.fw_p;                  {init to first entry in firmwares list}
  while fwent_p <> nil do begin        {back here each new list entry}
    mdev_resolve_fw (md, fwent_p^.fw_p^); {resolve dependencies for this firmware}
    fwent_p := fwent_p^.next_p;        {advance to next firmware in the list}
    end;                               {back to do next list entry}
  end;
