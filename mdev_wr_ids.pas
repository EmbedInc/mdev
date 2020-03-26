module mdev_wr_ids;
define mdev_wr_ids;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_IDS (FW, VERBOSE, STAT)
*
*   Write the <fwname>_IDS.MDEV file.  This file hard-codes the assigned MDEV
*   module IDS for the firmare FW.
}
procedure mdev_wr_ids (                {write MDEV file with assigned module IDs}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error encountered}
  end;
