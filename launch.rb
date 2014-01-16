#!/bin/ruby

puts "WoooOOOoooOO!"

Dir.chdir(File.dirname($0))
$: << 'lib'
$: << 'usr/lib/ruby/1.8/x86_64-linux'
$: << 'usr/lib/ruby/1.8'
require 'lib/bbs'
require 'lib/keymenu'
require 'lib/listmenu'
require 'lib/song'
require 'lib/user'

# Initialize
BBS.init
$0 = "GameBBS - nologin"
$user = nil

# Root menu
$loginmenu = BBS::KeyMenu.new IO.read('/dgl-banner')
$rootmenu  = BBS::KeyMenu.new IO.read('/dgl-banner')

$user = nil

# Modules
require 'modules/login'
require 'modules/gtnw'
require 'modules/songs'
# require 'modules/wumpus'
# require 'modules/hunt'
require 'modules/watch'
require 'modules/adom'
require 'modules/nethack'
require 'modules/slashem'
require 'modules/angband'
require 'modules/dcss'
# require 'modules/whatfools'

begin
  $loginmenu.run
rescue BBS::LoginException
  if $user
    $0 = "GameBBS - #{$user.login}"
    $rootmenu.run
  end
end

