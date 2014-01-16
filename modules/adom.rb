# Nethack games.

class User
  NETHACK_DEFAULT_RCFILE='/default-nethackrc'
  def adomdir
    path = $user.file('adomhome')
    unless File.exists?(path)
      Dir.mkdir path
    end
    path
  end
end

$rootmenu.add_choice('A',"Play Ancient Domains of Mystery") {
  adomhome = $user.adomdir
  ENV['HOME'] = adomhome
  BBS.puts "Making your adom home dir: #{adomhome}"
  BBS.puts "Beginning ADOM. Warning: Untested."
  BBS.pause
  $user.ttyrec('/adom/adom/adom')
}
