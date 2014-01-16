# Nethack games.

class User
  NETHACK_DEFAULT_RCFILE='/default-nethackrc'
  def nhoptions
    file = $user.file('nethackrc')
    unless File.exists?(file)
      # Copy the file over.
      File.open(file,'w') { |fout|
        fout.write(IO.read(NETHACK_DEFAULT_RCFILE))
      }
    end
    file
  end
end

$rootmenu.add_choice('n',"Play nethack") {
  ENV['NETHACKOPTIONS'] = "@#{$user.nhoptions}"
  ENV['HACKDIR'] = '/usr/games/lib/nethackdir'
  ENV['HACK'] = '/usr/games/lib/nethackdir/nethack'
  ENV['HACKPAGER'] = '/bin/less'
  BBS.clear
  if ($user.gamename.downcase == "wizard")
    BBS.puts "attempting debug/wizard mode."
    BBS.pause
    $user.ttyrec('/usr/games/lib/nethackdir/nethack','-D','-u',"wizard")
  else
    $user.ttyrec('/usr/games/lib/nethackdir/nethack','-u',$user.gamename)
  end
}

$rootmenu.add_choice('X',"Xplore nethack") {
  ENV['NETHACKOPTIONS'] = "@#{$user.nhoptions}"
  ENV['HACKDIR'] = '/usr/games/lib/nethackdir'
  ENV['HACK'] = '/usr/games/lib/nethackdir'
  ENV['HACKPAGER'] = '/bin/less'
  BBS.clear
  if ($user.gamename.downcase == "wizard")
    BBS.puts "attempting debug/wizard mode."
    BBS.pause
    $user.ttyrec('/usr/games/lib/nethackdir/nethack','-D','-u',"wizard")
  else
    $user.ttyrec('/usr/games/lib/nethackdir/nethack','-X','-u',"X_#{$user.gamename}")
  end
}

$rootmenu.add_choice('N','Nethack Options') {
  $user.edit('nethackrc')
}
