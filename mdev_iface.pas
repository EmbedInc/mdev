module mdev_iface;
define mdev_iface_get;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_IFACE_GET (MD, NAME, ENT_P)
*
*   Return ENT_P pointing to the global interfaces list entry for the interface
*   of name NAME.  The interface and global list entry is created if it does not
*   already exist.
}
procedure mdev_iface_get (             {get specific interfaces list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {interface name, case-sensitive}
  out     ent_p: mdev_iface_ent_p_t);  {returned pointer to global list entry}
  val_param;

var
  obj_p: mdev_iface_p_t;               {pointer to interface descriptor}

begin
  ent_p := md.iface_p;                 {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    if string_equal (ent_p^.iface_p^.name_p^, name) {found existing entry ?}
      then return;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
{
*   This is a new interface.
}
  util_mem_grab (                      {allocate mem for new descriptor}
    sizeof(obj_p^), md.mem_p^, false, obj_p);
  string_alloc (                       {allocate mem for name string}
    name.len, md.mem_p^, false, obj_p^.name_p);
  string_copy (name, obj_p^.name_p^);  {set name}
  obj_p^.desc_p := nil;                {init remaining descriptor fields}
  obj_p^.impl_p := nil;
  obj_p^.fw_p := nil;

  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.next_p := md.iface_p;         {fill in list entry}
  ent_p^.iface_p := obj_p;
  ent_p^.shared := false;
  md.iface_p := ent_p;                 {link to start of list}
  end;
