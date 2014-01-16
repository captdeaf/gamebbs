# song.rb
# play a song on a gamebbs terminal

module BBS
  def self.play_song(title,song)
    oldecho = BBS.echo
    BBS.echo = false
    BBS.clear
    BBS.puts title
    BBS.puts title.gsub(/./,'.')
    BBS.puts
    return if BBS.waitch(500) == 'q'
    song.each_line do |line|
      line.chomp.each_byte do |char|
        char = char.chr
        case char
        when '~'
          return if BBS.waitch(50) == 'q'
        when /\s/
          return if BBS.waitch(50) == 'q'
          BBS.print char
        else
          BBS.print char
          return if BBS.waitch(25) == 'q'
        end
      end
      sleep 0.5
      BBS.print "\n"
    end
    return if BBS.waitch(500) == 'q'
    BBS.puts
    BBS.puts
    BBS.puts "(Press any key to exit)"
    BBS.getch
  ensure
    BBS.echo = oldecho
  end
end

