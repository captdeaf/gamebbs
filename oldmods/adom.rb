# Nethack games.

amenu = BBS::KeyMenu.new("ADOM - Ancient Domains of Mystery")

amenu.add_choice('p',"Play ADOM") {
  BBS.clear
  $user.ttyrec('/bin/adom')
}

amenu.add_choice('c','Edit Config') {
  $user.edit('.adom.data/.adom.cfg')
}

amenu.add_choice('k','Edit Keybindings') {
  $user.edit('.adom.data/.adom.kbd')
}

$rootmenu.add_choice('A','Adom') {
  amenu.run
}
