module mdev_rd_file;
define mdev_rd_file;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine FILE_REQUIRES (MR, FILE, STAT)
}
procedure file_requires (              {processes REQUIRES command after the keyword}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  file: mdev_file_t;           {the file of the parent FILE command}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; internal;

var
  tk: string_treename_t;               {token read from current line}
  ent_p: mdev_file_ent_p_t;            {pointer to global files list entry}
  obj_p: mdev_file_p_t;                {pointer to file descriptor}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not hier_read_tk_req (mr.rd, tk, stat) then return; {get name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_file_get (mr.md_p^, tk, ent_p); {get files list entry for this file}
  obj_p := ent_p^.file_p;              {get pointer to the file descriptor}

  ent_p := file.dep_p;                 {init to first dependencies list entry}
  while ent_p <> nil do begin          {back here each new list entry}
    if ent_p^.file_p = addr(file) then return; {already in list ?}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {alloc mem for new dependencies list entry}
    sizeof(ent_p^), mr.md_p^.mem_p^, false, ent_p);
  ent_p^.file_p := obj_p;              {fill in list entry}
  ent_p^.next_p := file.dep_p;         {link new entry to start of list}
  file.dep_p := ent_p;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_RD_FILE (MR, STAT)
*
*   Process the FILE command.  The command keyword has just been read.
}
procedure mdev_rd_file (               {read FILE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param;

var
  tk: string_treename_t;               {token read from current line}
  ent_p: mdev_file_ent_p_t;            {pointer to global files list entry}
  obj_p: mdev_file_p_t;                {pointer to file descriptor}

begin
  tk.max := size_char(tk.str);         {init local var string}

  if not hier_read_tk_req (mr.rd, tk, stat) then return; {get name}
  if not hier_read_eol (mr.rd, stat) then return;

  mdev_file_get (mr.md_p^, tk, ent_p); {get files list entry for this file}
  obj_p := ent_p^.file_p;              {get pointer to the file descriptor}

  hier_read_block_start (mr.rd);       {enter the subordinate block}
  while hier_read_line (mr.rd, stat) do begin {back here each new subcommand}
    case hier_read_keyw_pick (mr.rd,
        'REQUIRES',
        stat) of

1:    begin                            {REQUIRES}
        file_requires (mr, obj_p^, stat);
        end;

      end;                             {end of subcommand cases}
    if sys_error(stat) then return;
    end;                               {back for next subcommand}
  end;
