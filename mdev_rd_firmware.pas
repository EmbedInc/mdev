module mdev_rd_firmware;
define mdev_rd_firmware;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_RD_FIRMWARE (MR, STAT)
*
*   Read the remainder of the FIRMWARE command.  The command name has been read.
*   STAT is assumed to be initialized to no error by the caller.
}
procedure mdev_rd_firmware (           {read FIRMWARE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

begin
	end;
