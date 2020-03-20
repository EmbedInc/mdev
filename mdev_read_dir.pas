module mdev_read_dir;
define mdev_read_dir;
define mdev_read_dirs;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_READ_DIR (MD, DIR, STAT)
*
*   Read all the MDEV files in the directory DIR, and add any new information to
*   the library use state MD.  Only MDEV files at the top level of DIR are read.
*   Subdirectories are not examined.
}
procedure mdev_read_dir (              {read all MDEV files in directory}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      dir: univ string_var_arg_t;  {directory name}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  conn: file_conn_t;                   {connection to the directory}
  curr: string_treename_t;             {saved original current directory name}
  finfo: file_info_t;                  {info about current directory entry}
  fnam: string_leafname_t;             {directory entry name}
  p: string_index_t;                   {parse index}
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  loop_ent, done_ents, abort2, abort1;

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  curr.max := size_char(curr.str);

  file_open_read_dir (                 {open the directory for reading it}
    dir,                               {directory name}
    conn,                              {returned connection to the directory}
    stat);
  if sys_error(stat) then return;

  file_currdir_get (curr, stat);       {save current directory name}
  if sys_error(stat) then goto abort1;
  file_currdir_set (conn.tnam, stat);  {go to target directory, for rel fnam interpret}
  if sys_error(stat) then goto abort1;

loop_ent:                              {back here to read each new directory entry}
  file_read_dir (                      {get next directory entry}
    conn,                              {connection to the directory}
    [file_iflag_type_k],               {get file system object type}
    fnam,                              {returned directory entry name}
    finfo,                             {returned additional info about dir entry}
    stat);
  if sys_error(stat) then goto done_ents; {didn't get a new directory entry ?}

  case finfo.ftype of                  {what type of object is this entry ?}
file_type_data_k,                      {ordinary data file}
file_type_link_k: begin                {symbolic link}
      if fnam.len < 6 then goto loop_ent; {name too short to be "x.mdev"}
      p := fnam.len - 4;               {set index to start of ".mdev"}
      if fnam.str[p] <> '.' then goto loop_ent; {name doesn't end in ".mdev" ?}
      p := p + 1;
      if fnam.str[p] <> 'm' then goto loop_ent;
      p := p + 1;
      if fnam.str[p] <> 'd' then goto loop_ent;
      p := p + 1;
      if fnam.str[p] <> 'e' then goto loop_ent;
      p := p + 1;
      if fnam.str[p] <> 'v' then goto loop_ent;

      mdev_read_file (md, fnam, stat); {read this MDEV file}
      end;
otherwise
    goto loop_ent;                     {ignore this directory entry, back for next}
    end;                               {end of object type cases}
  if sys_error(stat) then goto abort2;

  goto loop_ent;                       {back to do next directory entry}

done_ents:                             {done scanning all directory entries}
  discard( file_eof(stat) );           {end of directory is not error}

abort2:                                {jump here to abort while in DIR}
  if sys_error(stat)
    then begin                         {previous error}
      file_currdir_set (curr, stat2);  {try to go back to original curr dir}
      end
    else begin                         {no error so far}
      file_currdir_set (curr, stat);   {go back to original curr dir}
      end
    ;

abort1:                                {jump here to abort with dir open}
  file_close (conn);                   {close the connection to the directory}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_READ_DIRS (MD, DIR, STAT)
*
*   Read all the MDEV files in the directory DIR, and in any directory those
*   files reference, and any they reference, etc.  All new data is added to the
*   MDEV library use state MD.
}
procedure mdev_read_dirs (             {read MDEV files in dir and all referenced dirs}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      dir: univ string_var_arg_t;  {starting directory name}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  dent_p: mdev_dir_ent_p_t;            {points to global dir list entry for DIR}

begin
  mdev_dir_get (md, dir, dent_p);      {get pointer to global list entry for DIR}

  md.dir_read_p := dent_p;             {init to read this directory}
  repeat                               {loop over the remaining unread directories}
    mdev_read_dir (                    {read MDEV files in this directory}
      md, md.dir_read_p^.dir_p^.name_p^, stat);
    if sys_error(stat) then return;
    md.dir_read_p := md.dir_read_p^.next_p; {to next unread directory}
    until md.dir_read_p = nil;         {back until no unread directory left}

  mdev_check (md, stat);               {check for error in the resulting data}
  end;
