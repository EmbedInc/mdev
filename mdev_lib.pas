module mdev_lib;
define mdev_lib_start;
define mdev_lib_end;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine MDEV_INIT (MDEV)
*
*   Initialize all the fields in the library use state MDEV.  No resources will
*   be allocated.
}
procedure mdev_init (                  {init library use state}
  out    mdev: mdev_t);                {library use state to initialize}
 val_param; internal;

begin
  mdev.mem_p := nil;
  mdev.dir_p := nil;
  mdev.dir_curr_p := nil;
  mdev.iface_p := nil;
  mdev.file_p := nil;
  mdev.mod_p := nil;
  mdev.fw_p := nil;
 end;
{
********************************************************************************
*
*   Subroutine MDEV_LIB_START (MDEV, MEM)
*
*   Start a new use of the MDEV library.  MDEV is the library use state to set
*   up.  MEM is the parent memory context.  A subordinate memory context will be
*   created.
}
procedure mdev_lib_start (             {start a new MDEV library use instance}
  out     mdev: mdev_t;                {library use state to initialize}
  in out  mem: util_mem_context_t);    {parent mem context, subordinate will be created}
  val_param;

begin
 mdev_init (mdev);                     {init all fields of MDEV}
  util_mem_context_get (mem, mdev.mem_p); {create mem context for this library use}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_LIB_END (MDEV)
*
*   End a use of the MDEV library and deallocate any system resources used by
*   it.  The library use state MDEV will be returned invalid.
}
procedure mdev_lib_end (               {end library use instance, deallocate resources}
  in out  mdev: mdev_t);               {library use state, returned invalid}
  val_param;

begin
  if mdev.mem_p <> nil then begin
   util_mem_context_del (mdev.mem_p);  {deallocate all dynamic mem and mem context}
   end;
 mdev_init (mdev);                     {set the library use state to invalid}
 end;
