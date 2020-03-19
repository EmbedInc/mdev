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
*   Subroutine MDEV_SHOW_LIST_DIR (LIST_P, INDENT, SUB)
*
*   Show contents of directories list.
}
procedure mdev_show_list_dir (         {show directories list}
  in      list_p: mdev_dir_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  ent_p: mdev_dir_ent_p_t;             {pointer to current list entry}
  obj_p: mdev_dir_p_t;                 {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.dir_p;             {get pointer to the actual object}
    writeln ('':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_IFACE (LIST_P, INDENT, SUB)
*
*   Show contents of interfaces list.
}
procedure mdev_show_list_iface (       {show interfaces list}
  in      list_p: mdev_iface_ent_p_t;  {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  ent_p: mdev_iface_ent_p_t;           {pointer to current list entry}
  obj_p: mdev_iface_p_t;               {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.iface_p;           {get pointer to the actual object}

    write ('':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);
    if ent_p^.shared then begin
      write (' (shared)');
      end;
    writeln;

    if sub then begin
      writeln ('':indent+2, 'Description:');
      if obj_p^.desc_p <> nil then begin
        mdev_show_desc (obj_p^.desc_p^, indent+4);
        end;

      writeln ('':indent+2, 'From firmware:');
      mdev_show_list_fw (obj_p^.fw_p, indent+4, false);

      writeln ('':indent+2, 'From MDEV modules:');
      mdev_show_list_mod (obj_p^.impl_p, indent+4, false);
      end;

    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_FILE (LIST_P, INDENT, SUB)
*
*   Show contents of files list.
}
procedure mdev_show_list_file (        {show files list}
  in      list_p: mdev_file_ent_p_t;   {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  ent_p: mdev_file_ent_p_t;            {pointer to current list entry}
  obj_p: mdev_file_p_t;                {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.file_p;            {get pointer to the actual object}

    writeln ('':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);

    if sub then begin
      if obj_p^.dep_p <> nil then begin {depends-on list is not empty ?}
        writeln ('':indent+2, 'Requires:');
        mdev_show_list_file (obj_p^.dep_p, indent+4, false);
        end;
      end;

    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_MOD (LIST_P, INDENT, SUB)
*
*   Show contents of MDEV modules list.
}
procedure mdev_show_list_mod (         {show MDEV modules list}
  in      list_p: mdev_mod_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  ent_p: mdev_mod_ent_p_t;             {pointer to current list entry}
  obj_p: mdev_mod_p_t;                 {pointer to object of this list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.mod_p;             {get pointer to the actual object}

    writeln ('':indent, obj_p^.name_p^.str:obj_p^.name_p^.len);

    if sub then begin
      writeln ('':indent+2, 'Description:');
      if obj_p^.desc_p <> nil then begin
        mdev_show_desc (obj_p^.desc_p^, indent+4);
        end;

      writeln ('':indent+2, 'Uses:');
      mdev_show_list_iface (obj_p^.uses_p, indent+4, false);

      writeln ('':indent+2, 'Provides:');
      mdev_show_list_iface (obj_p^.impl_p, indent+4, false);

      writeln ('':indent+2, 'Template files:');
      mdev_show_list_file (obj_p^.templ_p, indent+4, false);

      writeln ('':indent+2, 'Source files:');
      mdev_show_list_file (obj_p^.files_p, indent+4, false);

      writeln ('':indent+2, 'Include files:');
      mdev_show_list_file (obj_p^.incl_p, indent+4, false);
      end;

    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_SHOW_LIST_FW (LIST_P, INDENT, SUB)
*
*   Show contents of firmwares list.
}
procedure mdev_show_list_fw (          {show firmwares list}
  in      list_p: mdev_fw_ent_p_t;     {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param;

var
  ent_p: mdev_fw_ent_p_t;              {pointer to current list entry}
  obj_p: mdev_fw_p_t;                  {pointer to object of this list entry}
  id: sys_int_machine_t;               {assigned ID of a module}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.fw_p;              {get pointer to the actual object}

    write ('':indent);
    if obj_p^.context_p^.len > 0 then begin
      write ('(', obj_p^.context_p^.str:obj_p^.context_p^.len, ') ');
      end;
    writeln (obj_p^.name_p^.str:obj_p^.name_p^.len);

    if sub then begin
      writeln ('':indent+2, 'Provides:');
      mdev_show_list_iface (obj_p^.impl_p, indent+4, false);

      writeln ('':indent+2, 'Modules supported:');
      mdev_show_list_mod (obj_p^.mod_p, indent+4, false);

      writeln ('':indent+2, 'Module IDs:');
      for id := mdev_modid_min_k to mdev_modid_max_k do begin
        if obj_p^.modids[id] <> nil then begin
          writeln ('':indent+4, id,
            ': ', obj_p^.modids[id]^.name_p^.str:obj_p^.modids[id]^.name_p^.len);
          end;
        end;                           {back for next possible module ID}
      end;                             {end of sub-level information enabled}

    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to show this new list entry}
  end;
