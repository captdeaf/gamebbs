# songs module

songmenu = BBS::ListMenu.new("Pick a song to play") { |stitle,song|
    BBS.play_song(stitle,IO.read(song))
}

Dir.glob("songs/*.txt").each do |song|
  song =~ /songs\/(.+)\.txt$/
  stitle = $1
  songmenu.add_choice(stitle,[stitle,song])
end

$loginmenu.add_choice('L','Random lyrics from songs-poems.') do
  songmenu.run
end

$rootmenu.add_choice('L','Random lyrics from songs-poems.') do
  songmenu.run
end

