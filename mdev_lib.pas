module mdev_lib;
define mdev_lib_start;
define mdev_lib_end;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine MDEV_INIT (MD)
*
*   Initialize all the fields in the library use state MD except the MEM_ field.
}
procedure mdev_init (                  {init library use state}
  out    md: mdev_t);                  {library use state to initialize}
  val_param; internal;

begin
  md.dir_p := nil;
  md.dir_read_p := nil;
  md.iface_p := nil;
  md.file_p := nil;
  md.mod_p := nil;
  md.fw_p := nil;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_LIB_START (MD, MEM)
*
*   Start a new use of the MDEV library.  MDEV is the library use state to set
*   up.  MEM is the parent memory context.  A subordinate memory context will be
*   created.
}
procedure mdev_lib_start (             {start a new MDEV library use instance}
  out     md: mdev_t;                  {library use state to initialize}
  in out  mem: util_mem_context_t);    {parent mem context, subordinate will be created}
  val_param;

begin
  mdev_init (md);                      {init all fields of MDEV}
  util_mem_context_get (mem, md.mem_p); {create mem context for this library use}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_LIB_END (MD)
*
*   End a use of the MDEV library and deallocate any system resources used by
*   it.  The library use state MDEV will be returned invalid.
}
procedure mdev_lib_end (               {end library use instance, deallocate resources}
  in out  md: mdev_t);                 {library use state, returned invalid}
  val_param;

begin
  if md.mem_p <> nil then begin
    util_mem_context_del (md.mem_p);   {deallocate all dynamic mem and mem context}
    end;
  mdev_init (md);                      {set the library use state to invalid}
  end;
