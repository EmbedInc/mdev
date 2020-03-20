module mdev_check;
define mdev_check;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_CHECK (MD, STAT)
*
*   Check the current MDEV data for errors, consistancy, etc.  This routine
*   stops at the first error found, and returns STAT accordingly.  When the
*   entire data is checked and no errors found, STAT is returned indicating no
*   error.
}
procedure mdev_check (                 {check all data for errors}
  in out  md: mdev_t;                  {MDEV library use state}
  out     stat: sys_err_t);            {returned error status}
  val_param;

var
  ifcent_p: mdev_iface_ent_p_t;        {points to interfaces list entry}
  ifc_p: mdev_iface_p_t;               {points to interface descriptor}

begin
  sys_error_none (stat);               {init to no error encountered}
{
*   Check that all interfaces were formally defined.  This is determined by them
*   having a description string.
}
  ifcent_p := md.iface_p;              {init to first list entry}
  while ifcent_p <> nil do begin       {scan the list}
    ifc_p := ifcent_p^.iface_p;        {get pointer to the interface}
    if ifc_p^.desc_p = nil then begin  {this interface is undefined ?}
      if ifc_p^.fw_p <> nil then begin {implemented by at least one firmware ?}
        sys_stat_set (mdev_subsys_k, mdev_stat_unface_fw_k, stat);
        sys_stat_parm_vstr (           {add interface name}
          ifc_p^.name_p^, stat);
        sys_stat_parm_vstr (           {add first firmware name}
          ifc_p^.fw_p^.fw_p^.name_p^, stat);
        return;
        end;
      if ifc_p^.impl_p <> nil then begin {implemented by at least one module ?}
        sys_stat_set (mdev_subsys_k, mdev_stat_unface_mod_k, stat);
        sys_stat_parm_vstr (           {add interface name}
          ifc_p^.name_p^, stat);
        sys_stat_parm_vstr (           {add first module name}
          ifc_p^.impl_p^.mod_p^.name_p^, stat);
        return;
        end;
      sys_stat_set (mdev_subsys_k, mdev_stat_unface_k, stat);
      sys_stat_parm_vstr (ifc_p^.name_p^, stat); {interface name}
      return;
      end;
    ifcent_p := ifcent_p^.next_p;      {to next list entry}
    end;                               {back to process this new list entry}
  end;
