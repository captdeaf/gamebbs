#!/usr/bin/ruby

require('curses')

module BBS
  class LoginException < Exception
  end
  class << self
    attr_reader :win
    attr_accessor :echo
    def init
      Curses.init_screen
      # @win = Curses::Window.new(0,0,0,0)
      @win = Curses.stdscr
      reset
    end
    def reset
      Curses.cbreak
      Curses.nonl
      Curses.noecho
      @win.scrollok 0
      @win.keypad = true
      @echo = true
      trap('INT') {
        exit
      }
    end
    def safecall(what="calling a method")
      @count ||=5
      return unless block_given?
      begin
        yield
      rescue LoginException
        raise LoginException
      rescue Exception => er
        @count -= 1
        exit if @count < 1
        BBS.clear
        BBS.puts
        BBS.puts
        BBS.puts "   There was an error while calling that function:"
        BBS.puts
        BBS.puts "   " + er.message
        BBS.puts
        BBS.puts "   " + er.backtrace[0,3].join("\n   ")
        BBS.puts
        BBS.puts
        BBS.pause
      end
    end
    def execute(*args)
      Curses.nocbreak
      Curses.nl
      Curses.echo
      @win.keypad = false
      BBS.clear
      BBS.puts "Executing: #{args.join(' ')}"
      pid = fork do
        exec(*args)
      end
      yield pid if block_given?
      Process.waitpid pid
    ensure
      reset
    end
    def clear
      @win.clear
    end
    def display(text)
      @win.clear
      @win.addstr text
      @win.refresh
    end
    def x
      @win.maxx
    end
    def y
      @win.maxy
    end
    def pause(text=nil)
      BBS.puts
      if text
        BBS.puts '  ' + text
        BBS.puts
      end
      BBS.puts "  ( Press any key to continue )"
      BBS.getch
    end
    def print(text)
      @win.addstr text
      @win.refresh
    end
    def puts(text='')
      @win.addstr text
      @win.addstr "\n"
      @win.refresh
    end
    def gets(passwd=false)
      s = ''
      loop do
        ch = @win.getch
        exit if (ch > 65535)
        if ch == 127 || ch == 8
          if s.size > 0
            s = s[0..-2]
            if @echo
              BBS.print 8.chr
              BBS.print ' '
              BBS.print 8.chr
            end
          end
          next
        end
        next unless ch < 255
        ch = ch.chr
        next unless (ch =~ /[\s\S]/)
        break if ["\n","\r"].include?(ch)
        print ch unless (passwd or ! @echo) 
        s << ch
      end
      print "\n"
      s
    end
    def yorn(question)
      print "#{question} (y/n)"
      loop do
        ch = getch
        if ['y','Y'].include?(ch)
          return true
        elsif ['n','N'].include?(ch)
          return false
        end
      end
    end
    def getch
      ch = @win.getch
      exit if (ch > 65535)
      if (ch < 255)
        ch = ch.chr
        if @echo
          print ch.chomp
        end
      end
      ch
    end
    def waitch(timeout=1000)
      @win.nodelay = true
      @win.timeout = timeout
      ch = @win.getch
      @win.nodelay = false
      if ch > 255
        return nil
      end
      ch = ch.chr
      print ch if @echo
      ch
    end
  end
end
