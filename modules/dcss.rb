# Nethack games.

class User
  DCSS_DEFAULT_RCFILE='/default-dcss'
  def dcssoptions
    file = $user.file('dcss')
    unless File.exists?(file)
      # Copy the file over.
      File.open(file,'w') { |fout|
        fout.write(IO.read(DCSS_DEFAULT_RCFILE))
      }
    end
    file
  end
end
$dcssmenu  = BBS::KeyMenu.new "Dungeon Crawl: Stone Soup"

$dcssmenu.add_choice('a', "Play DC:SS 0.6.1") {
  BBS.clear
  $user.ttyrec('/stonesoup-0.6.1/crawl-ref/ncrawl',
               '-name', $user.gamename,
               '-rcdir', '/stonesoup-0.6.1/crawl-ref/settings',
               '-rc', $user.dcssoptions)
}

$dcssmenu.add_choice('h', "Play DC:SS HEAD version") {
  BBS.clear
  $user.ttyrec('/stonesoup-head/crawl-ref/ncrawl',
               '-name', $user.gamename,
               '-rcdir', '/stonesoup-head/crawl-ref/settings',
               '-rc', $user.dcssoptions)
}

$dcssmenu.add_choice('D','Edit your DC:SS RC file') {
  $user.dcssoptions
  $user.edit('dcss')
}

$rootmenu.add_choice('d',"Dungeon Crawl: Stone Soup") {
  $dcssmenu.run
}
