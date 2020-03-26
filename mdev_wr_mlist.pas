module mdev_wr_mlist;
define mdev_wr_mlist;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_MLIST (FW, VERBOSE, STAT)
*
*   Edit the MLIST file for the firmware FW to include all the MDEV modules.
*   The file is always read, then overwritten, with the modules in alphabetic
*   order.
}
procedure mdev_wr_mlist (              {edit MLIST file to include MDEV modules}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no errors encountered}
 end;
