# songs module

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
