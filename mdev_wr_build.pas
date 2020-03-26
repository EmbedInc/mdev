module mdev_wr_build;
define mdev_wr_build;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_BUILD (FW, VERBOSE, STAT)
*
*   Write the build scripts specific to the MDEV modules in the firmware FW.
*   The following scripts are written:
*
*     build_mdevs_init
*
*       Intended to be called from the BUILD_FWINIT script.  It fetches files
*       required for building MDEV modules, except for the top module source
*       files themselves.
*
*     build_mdevs
*
*       Intended to be called from the BUILD_FW script.  It builds the MDEV
*       source modules.
}
procedure mdev_wr_build (              {write BUILD_MDEVS scripts}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no errors encountered}
 end;
