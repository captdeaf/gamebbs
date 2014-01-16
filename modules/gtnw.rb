# Global Thermonuclear War

$rootmenu.add_choice('g',"Global Thermo-Nuclear War") {
  BBS.clear
  BBS.puts
  BBS.puts
  BBS.puts "  Welcome to Global Thermonuclear War. You have the first strike."
  BBS.puts
  BBS.puts "  You are America. Where do you first choose to strike?"
  BBS.puts
  BBS.print "  Enter location: "
  BBS.echo = true
  where = BBS.gets
  BBS.puts
  BBS.puts
  if ['nowhere','nothing'].include?(where.downcase.strip)
    BBS.puts "  Smart move."
    BBS.puts
    sleep 1.0
    BBS.puts "  Sometimes the only way to win is not to play."
    BBS.puts
    sleep 1.0
    BBS.puts "  ( press any key to quit )"
    BBS.getch
  else
    "  ... *BANG*".scan(/./) { |s|
      sleep 0.2
      BBS.print s
    }
    sleep 0.5
    BBS.puts
    BBS.puts
    BBS.puts "  You shoot, I shoot, everybody loses."
    BBS.puts
    sleep 3.0
    BBS.puts "  Sometimes the only way to win is not to play."
    BBS.puts
    sleep 4.0
    BBS.puts "  ( press any key to quit )"
    BBS.getch
  end
}
