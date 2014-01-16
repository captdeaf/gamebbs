# Nethack games.

class User
  SLASHEM_DEFAULT_RCFILE='/default-slashemrc'
  def slashoptions
    file = $user.file('slashemrc')
    unless File.exists?(file)
      # Copy the file over.
      File.open(file,'w') { |fout|
        fout.write(IO.read(SLASHEM_DEFAULT_RCFILE))
      }
    end
    file
  end
end

$rootmenu.add_choice('s',"Play Slash 'em") {
  ENV['SLASHEMOPTIONS'] = "@#{$user.slashoptions}"
  ENV['HACKDIR'] = '/usr/share/games/slashem'
  ENV['HACK'] = '/usr/lib/games/slashem/slashem'
  ENV['HACKPAGER'] = '/bin/less'
  BBS.clear
  $user.ttyrec('/usr/lib/games/slashem/slashem','-u',$user.gamename)
}

$rootmenu.add_choice('S','Slash Options') {
  $user.edit('slashemrc')
}
