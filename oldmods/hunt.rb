# Nethack games.

$rootmenu.add_choice('H',"Hunt (other players!)") {
  BBS.clear
  $user.ttyrec('/bin/hunt','-n',$user.login,'everest')
}
