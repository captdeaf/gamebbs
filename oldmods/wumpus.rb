# Nethack games.

$rootmenu.add_choice('h',"Hunt the Wumpus") {
  BBS.clear
  $user.ttyrec('/bin/wump')
}
