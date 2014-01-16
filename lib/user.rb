# user.rb

# The global user.
class User
  attr_reader :login
  def User.find(un)
    if File.exists?("/users/#{un.downcase}")
      self.new(un.downcase)
    else
      nil
    end
  end
  def initialize(l)
    l = l.downcase
    @login = l
    @home = "/users/#{l}"
    ENV['HOME'] = "/users/#{l}"
    ENV['MAIL'] = "/users/#{l}/mailfile"
    ENV['MAILREADER'] = "/bin/mymail"
  end
  def mail(message)
    from = 'unknown'
    from = $user.login if $user
    m = "#{from}: #{message}"
    File.open(file('mailfile'),'a') do |f|
      f.puts m
    end
  end
  def pass
    IO.read(file('password')).chomp
  end
  def email
    IO.read(file('email')).chomp
  end
  def gamename
    IO.read(file('gamename')).chomp
  end
  def edit(filename)
     BBS.clear
     BBS.puts "Editing #{filename}"
     BBS.execute("/bin/nano -R -w #{file(filename)}")
  end
  def edit_path(filename)
     BBS.clear
     BBS.puts "Editing #{filename}"
     BBS.execute("/bin/nano -R -w #{filename}")
  end
  def file(name)
    File.join(@home,name)
  end
  def huppit(done=false)
    lines = []
    IO.popen('/bin/ps auxww','r') do |fin|
      lines = fin.readlines
    end
    lines.collect! { |line|
      arr = line.split(/\s+/)
      [ arr[0], arr[1], arr[10,100].join(' ') ]
    }
    lines = lines.select { |user, pid, cmd|
      next unless user == '1016'
      next unless cmd =~ /ttyrec\/(\w+)\//
      next unless $1 == login
      next if     cmd =~ /ttyplay/
      true
    }
    return true if lines.empty?
    BBS.clear
    if done
      BBS.puts <<EOF


  I seem to have been unable to kill the process. Please try again, or
  contact Walker.

EOF
    else
      BBS.puts <<EOF


  You appear to already be running a game. Would you like to end the game
  in progress? (by HUPing it) ?

EOF
    end
    return false unless BBS.yorn("Kill old game?")
    BBS.puts
    BBS.puts "  Terminating the TTYREC processes ..."
    lines.each do |u,pid,cmd|
      Process.kill('TERM',pid.to_i)
    end
    sleep 3
    # Make sure we exited.
    huppit(true)
  end
  def ttyrec(*args)
    exit unless huppit
    date = Time.now.strftime('%Y-%m-%d.%H:%M:%S')
    unless Dir.glob("/dgldir/inprogress/#{@login}:*").empty?
      BBS.clear
      BBS.puts "  Sorry, it looks like you already have a game running."
      BBS.puts "  Walker will add functionality to deal with it tomorrow."
      BBS.pause
    else
      lockfile = "/dgldir/inprogress/#{login}:#{date}.ttyrec"
      ttyfile = "/dgldir/ttyrec/#{login}/#{date}.ttyrec"
      lf = File.open(lockfile,'w') { |fout| fout.close }
      recorder = '/gamebbs/gttyrec'
      # recorder = './sttyrec' if $user.login == 'walker'
      BBS.execute(recorder, '-o', ttyfile, *args) { |pid|
        lf = File.open(lockfile,'w') { |lf|
          lf.puts File.basename(args[0])
          lf.puts pid.to_s
        }
      }
      File.unlink(lockfile)
      BBS.clear
    end
  end
end
