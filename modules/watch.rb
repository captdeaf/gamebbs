# songs module

watchmenu = BBS::ListMenu.new("Pick a game to watch. During playback, 's' will change your charset. 'm' will send a message. 'q' will quit.") { |choice|
  gamefile = choice
  who = nil
  if gamefile =~ /^\/dgldir\/ttyrec\/(\w+)\/(.+).ttyrec$/
    who = User.find($1)
    if who
      who.mail "I'm WATCHING you!"
      true
    end
  end
  from = 'unknown'
  from = $user.login if $user
  mailcmd = "/bin/ruby /bin/message #{who.login} #{from}"
  BBS.puts "Executing: ./gttyplay -f #{gamefile} -m \"#{mailcmd}\""
  BBS.clear()
  BBS.execute("./gttyplay", "-f", "#{gamefile}", "-m", "#{mailcmd}")
  BBS.clear()
  watchmenu.refresh
}

watchmenu.bottomline = 'Hit space to refresh'

watchmenu.on_space {
  watchmenu.refresh
}

def watchmenu.refresh
  empty()
  now = Time.now.to_i
  Dir.glob("/dgldir/inprogress/*.ttyrec").each do |game|
    File.basename(game) =~ /^(\w+):(.*?)\.ttyrec$/
    player = $1
    gamefile = "/dgldir/ttyrec/#{$1}/#{$2}.ttyrec"
    next unless File.exists?(gamefile)
    idletime = now - File.stat(gamefile).mtime.to_i
    idles = []
    if idletime > 86400
      idles << (idletime/86400).to_s + 'd'
      idletime %= 86400
    end
    if idletime > 3600
      idles << (idletime/3600).to_s + 'h'
      idletime %= 3600
    end
    if idletime > 60
      idles << (idletime/60).to_s + 'm'
      idletime %= 60
    end
    idles << idletime.to_s + 's'
    gamename = IO.readlines(game)[0].chomp
    subj = "#{gamename.rjust(12)}: #{$1.ljust(13)} - idle for #{idles.join(' ')}"
    add_choice(subj,gamefile)
  end
end

$loginmenu.add_choice('w','Watch ongoing games.') do
  watchmenu.refresh
  watchmenu.run
end

$rootmenu.add_choice('w','Watch ongoing games.') do
  watchmenu.refresh
  watchmenu.run
end

pastgamelist = BBS::ListMenu.new("Whose games would you like to watch?") { |who|
  pastgamelist.showlist(who)
}

pastgamelist.bottomline = 'Hit space to refresh'

pastgamelist.on_space {
  pastgamelist.refresh
}

def pastgamelist.showlist(recdir)
  name = File.basename(recdir)
  banner = "#{name}'s recorded files.\n
      File name.            Size."
  ls = BBS::ListMenu.new(banner) { |gamefile|
    BBS.puts "Executing: ./sttyplay #{gamefile}"
    BBS.clear()
    BBS.execute("./sttyplay #{gamefile}")
  }
  Dir.glob("#{recdir}/*.ttyrec").sort.each do |gf|
    fn = File.basename(gf)
    sz = File.stat(gf).size
    subj = "#{fn.ljust(18)} - #{sz.to_s.rjust(10)}."
    ls.add_choice(subj,gf)
  end
  ls.run
end

def pastgamelist.refresh
  empty()
  now = Time.now.to_i
  Dir.glob('/dgldir/ttyrec/*').sort.each do |recdir|
    next unless File.directory?(recdir)
    name = File.basename(recdir)
    count = Dir.glob("#{recdir}/*.ttyrec").size
    subj = "#{name.ljust(14)} - #{count.to_s.rjust(4)} files."
    add_choice(subj,recdir)
  end
end

$rootmenu.add_choice('W','Watch past games') do
  pastgamelist.refresh
  pastgamelist.run
end
