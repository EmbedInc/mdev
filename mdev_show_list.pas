module mdev_show_list;
define mdev_show_list_dir;
define mdev_show_list_iface;
define mdev_show_list_file;
define mdev_show_list_mod;
define mdev_show_list_fw;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_DIR (LIST_P, INDENT)
*
*   Show contents of directories list.
}
procedure mdev_show_list_dir (         {show directories list}
  in      list_p: mdev_dir_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t);  {number of spaces to indent each line}
  val_param;

var
  ent_p: mdev_dir_ent_p_t;             {pointer to current list entry}
  obj_p: mdev_dir_p_t;                 {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.dir_p;             {get pointer to the actual object}
    writeln (' ':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_IFACE (LIST_P, INDENT)
*
*   Show contents of interfaces list.
}
procedure mdev_show_list_iface (       {show interfaces list}
  in      list_p: mdev_iface_ent_p_t;  {pointer to first list entry}
  in      indent: sys_int_machine_t);  {number of spaces to indent each line}
  val_param;

var
  ent_p: mdev_iface_ent_p_t;           {pointer to current list entry}
  obj_p: mdev_iface_p_t;               {pointer to object of this list entry}
  fw_p: mdev_fw_ent_p_t;               {pointer to current firmware list entry}
  mod_p: mdev_mod_ent_p_t;             {pointer to current modules list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.iface_p;           {get pointer to the actual object}

    write (' ':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);
    if ent_p^.shared then begin
      write (' (shared)');
      end;
    writeln;

    writeln (' ':indent, 'Description:');
    if obj_p^.desc_p <> nil then begin
      mdev_show_desc (obj_p^.desc_p^, indent+2);
      end;

    writeln (' ':indent, 'From firmware:');
    fw_p := obj_p^.fw_p;               {init to first firmware list entry}
    while fw_p <> nil do begin
      writeln (' ':(indent + 2), fw_p^.fw_p^.name_p^.str:fw_p^.fw_p^.name_p^.len);
      fw_p := fw_p^.next_p;
      end;

    writeln (' ':indent, 'From MDEV modules:');
    mod_p := obj_p^.impl_p;
    while mod_p <> nil do begin
      writeln (' ':(indent + 2), mod_p^.mod_p^.name_p^.str:mod_p^.mod_p^.name_p^.len);
      mod_p := mod_p^.next_p;
      end;

    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_FILE (LIST_P, INDENT)
*
*   Show contents of files list.
}
procedure mdev_show_list_file (        {show files list}
  in      list_p: mdev_file_ent_p_t;   {pointer to first list entry}
  in      indent: sys_int_machine_t);  {number of spaces to indent each line}
  val_param;

var
  ent_p: mdev_file_ent_p_t;            {pointer to current list entry}
  obj_p: mdev_file_p_t;                {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.file_p;            {get pointer to the actual object}



    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_MOD (LIST_P, INDENT)
*
*   Show contents of MDEV modules list.
}
procedure mdev_show_list_mod (         {show MDEV modules list}
  in      list_p: mdev_mod_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t);  {number of spaces to indent each line}
  val_param;

var
  ent_p: mdev_mod_ent_p_t;             {pointer to current list entry}
  obj_p: mdev_mod_p_t;                 {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.mod_p;             {get pointer to the actual object}



    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_FW (LIST_P, INDENT)
*
*   Show contents of firmwares list.
}
procedure mdev_show_list_fw (          {show firmwares list}
  in      list_p: mdev_fw_ent_p_t;     {pointer to first list entry}
  in      indent: sys_int_machine_t);  {number of spaces to indent each line}
  val_param;

var
  ent_p: mdev_fw_ent_p_t;              {pointer to current list entry}
  obj_p: mdev_fw_p_t;                  {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.fw_p;              {get pointer to the actual object}



    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
