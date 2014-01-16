# login routines
# 
# walker:walker@deafcode.com:deTDTxFRguyYw:

$rootmenu.add_choice('P','Change your password') {
  BBS.clear
  BBS.puts
  BBS.puts "  Change password:"
  BBS.puts
  BBS.print "  New password: "
  BBS.echo = false
  pass = BBS.gets
  BBS.puts
  BBS.puts
  BBS.puts
  BBS.print "  Verify pass: "
  pass2 = BBS.gets
  BBS.puts
  BBS.puts
  BBS.puts
  BBS.echo = true
  if pass2 != pass
    BBS.pause("Passwords don't match.")
    next
  end
  if pass.size < 4
    BBS.pause('Password is too small')
    next
  end
  File.open($user.file('password'),'w') do |fout|
    fout.puts pass.crypt(pass)
  end
  BBS.pause('Password changed.')
}

$rootmenu.add_choice('e','Change your email address') {
  BBS.clear
  BBS.puts
  BBS.puts "  Change email address:"
  BBS.puts
  BBS.puts "  Old email address: #{$user.email}"
  BBS.puts
  BBS.puts
  BBS.puts
  BBS.print "  New email address: "
  BBS.echo = true
  email = BBS.gets
  if (email.size > 5 and email =~ /\@/)
    File.open($user.file('email'),'w') do |fout|
      fout.puts email
    end
  end
  BBS.pause('E-mail changed')
}

$loginmenu.add_choice('l','Login') do
  BBS.clear
  BBS.puts 
  BBS.puts 
  BBS.puts 
  BBS.puts '  Logging in:'
  BBS.puts 
  BBS.echo = true
  BBS.print '  Username: '
  un = BBS.gets.downcase.delete('^a-z0-9')
  case
  when un.empty?
    nil
  when ! File.exists?("/users/#{un}")
    BBS.pause('No such user.')
  when ! File.exists?("/users/#{un}/password")
    BBS.pause("Weird, you're registered but no password. Bug Walker.")
  # when un == "walker"
    # BBS.pause "Get the fuck outta here, nitwit."
  else
    user = User.new(un)
    BBS.echo = false
    BBS.print '  Password: '
    pass = BBS.gets
    BBS.echo = true
    if pass.nil? or pass == ''
      next
    end
    if user.pass == pass.crypt(pass)
      BBS.puts
      BBS.puts "  Welcome, #{user.login}!"
      $user = user
      sleep 0.5
      raise BBS::LoginException
    else
      BBS.pause('Invalid password.')
    end
  end
end

$loginmenu.add_choice('r','Register') do
  BBS.clear
  BBS.puts 
  BBS.puts '  Register:'
  BBS.puts 
  BBS.echo = true
  BBS.print '  Username: '
  gamename = BBS.gets.delete('^A-Za-z0-9')
  un = gamename.downcase
  user = nil
  BBS.puts
  next unless BBS.yorn("  '#{gamename}' okay?")
  case
  when File.exists?("/users/#{un}")
    BBS.pause "That username is already taken."
    next
  when un.size < 3
    BBS.pause "That username is too short."
    next
  when un.size > 12
    BBS.pause "That username is too long."
    next
  end
  found = false
  BBS.puts
  BBS.puts "  Please give us a password. And remember that over telnet,"
  BBS.puts "  passwords are sent in plain text, so do not choose one you"
  BBS.puts "  wish to remain secure."
  BBS.puts
  pass = loop do
    BBS.print '  Password: '
    BBS.echo = false
    pass1 = BBS.gets
    BBS.print "\n"
    BBS.print '  Password again: '
    pass2 = BBS.gets
    BBS.echo = true
    BBS.puts
    case
    when pass1 != pass2
      BBS.puts '  passwords do not match.'
      next
    when pass1.empty?
      break nil
    when pass1.size < 4
      BBS.puts '  password too small.'
      next
    when pass1.size > 8
      BBS.puts '  password too big.'
      next
    else
      break pass1
    end
  end

  next unless pass

  email = loop do
    BBS.puts
    BBS.print '  Email address: '
    BBS.puts
    e = BBS.gets
    break e if BBS.yorn("  '#{e}' correct?")
  end
  if File.exists?("/users/#{un}")
    BBS.pause "Weirdness happened... Bug Walker."
    next
  end
  Dir.mkdir("/users/#{un}")
  Dir.mkdir("/dgldir/ttyrec/#{un}")
  user = User.new(un)
  File.open(user.file('password'),'w') { |f| f.puts pass.crypt(pass) }
  File.open(user.file('email'),'w') { |f| f.puts email }
  File.open(user.file('gamename'),'w') { |f| f.puts gamename }
  BBS.puts
  BBS.puts "  Welcome, #{user.gamename}!"
  $user = user
  sleep 0.5
  raise BBS::LoginException
end
