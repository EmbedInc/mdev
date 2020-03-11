module mdev_rd_module;
define mdev_rd_module;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_RD_MODULE (MR, STAT)
*
*   Read the remainder of the MODULE command.  The command name has been read.
*   STAT is assumed to be initialized to no error by the caller.
}
procedure mdev_rd_module (             {read MODULE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

begin
  end;
