module mdev_wr_templ;
define mdev_wr_templ_list;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_WR_TEMPL_LIST (FW, VERBOSE, STAT)
*
*   Create the MDEV module source files that are modified from templates.  These
*   files are only created if they do not previously exist.
}
procedure mdev_wr_templ_list (         {write the source files modified from templates}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no errors encountered}
  end;
