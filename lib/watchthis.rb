#!/usr/bin/ruby

module BBS
  class << self
    def exec_record(filename,
      Curses.nocbreak
      Curses.nl
      Curses.echo
      @win.keypad = false
      yield
      reset
    end
  end
end
