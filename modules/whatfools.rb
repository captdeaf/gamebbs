# Oh what fools these mortals be!

$rootmenu.add_choice('f',"Oh what Fools these Mortals be!") {
  BBS.execute("/bin/python /bin/WhatFools.py")
  sleep 3
  BBS.clear
}

