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

$rootmenu.add_choice('a',"Angband - Experimental") {
  BBS.clear
  pwd = Dir.pwd
  Dir.chdir '/usr/games/lib/angband'
  $user.ttyrec('/usr/games/angband',"-u#{$user.gamename}")
  Dir.chdir pwd
}

# $rootmenu.add_choice('S','Slash Options') {
#   $user.edit('slashemrc')
# }
