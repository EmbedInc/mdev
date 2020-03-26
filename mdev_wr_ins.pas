module mdev_wr_ins;
define mdev_wr_ins_init;
define mdev_wr_ins_main;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_INS_INIT (FW, VERBOSE, STAT)
*
*   Write the MDEVS_INIT.INS.DSPIC include file.  This file contains code to
*   initialize all the MDEV modules.
}
procedure mdev_wr_ins_init (           {write initialization include file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
 sys_error_none (stat);                {init to no errors encountered}
 end;
{
********************************************************************************
*
*   Subroutine MDEV_WR_INS_MAIN (FW, VERBOSE, STAT)
*
*   Write the MDEVS.INS.DSPIC file.  This file contains definitions that need to
*   be global to the firmware FW.  It also references all the global include
*   files required by the MDEV modules.
}
procedure mdev_wr_ins_main (           {write main MDEV include file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
 sys_error_none (stat);                {init to no errors encountered}
 end;
