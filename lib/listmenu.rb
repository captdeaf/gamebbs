# menu.rb
#
# The menu class for the BBS module.

require 'text/format'

module BBS
  class ListMenu
    attr_accessor :bottomline
    def initialize(banner,&block)
      raise "ListMenu requires a block on creation" unless block_given?
      @banner = []
      banner.split(/\n/).each do |ban|
      fmt = Text::Format.new(ban)
      fmt.columns = 70
      fmt.body_indent = 6
      fmt.first_indent = 6
      @banner += fmt.format.split(/\n/)
      end
      @banner << ''
      @choices = []
      @pages = []
      @pagevals = []
      @onspace = lambda { true }
      @bottomline = ''
      @texts = []
      @block = block
      build
    end
    def on_space(&block)
      @onspace = block
      @onspace ||= lambda { true }
    end
    def add_choice(text,value)
      rows = text.split(/\n/)
      if (rows.size > 2 || rows[0].size > 50 || (rows[1] && rows[1].size > 50))
        fmt = Text::Format.new(text)
        fmt.columns = 50
        fmt.left_margin = 0
        fmt.body_indent = 0
        fmt.first_indent = 0
        rows = fmt.format.split(/\n/)
      end
      raise 'text for choice must fit in 2 lines' unless rows.size < 3
      @choices << [rows,value]
      @texts << text
      build
    end
    def delete_choice(text)
      i = @texts.index(text)
      @choices.delete_at i
      @texts.delete_at i
      build
    end
    def empty
      @texts = []
      @choices = []
      build
    end
    def build
      puts "Building"
      maxrows = 19
      maxrows -= @banner.size
      # How many rows we have to work with.
      @pages = []
      @pagevals = []
      rows = maxrows
      key = 'a'
      curpage = []
      curvals = []
      @choices.each do |clines,value|
        choice = clines.dup
        case
        when rows < clines.size
          @pages << curpage
	  @pagevals << curvals
          key = 'a'
          choice[0] = "    #{key} - #{choice[0]}"
          choice[1] = "        #{choice[1]}" if choice.size > 1
          curpage = []
	  curvals = []
          rows = maxrows
          curpage += choice
	  curvals << value
          rows -= choice.size
        else
          choice[0] = "    #{key} - #{choice[0]}"
          choice[1] = "        #{choice[1]}" if choice.size > 1
          curpage += choice
	  curvals << value
          rows -= choice.size
        end
	key.succ!
        key.succ! if key == 'q'
      end
      @pages << curpage
      @pagevals << curvals
    end
    def display_page(pagenum,mess)
      text = [''] + @banner
      # text += Array.new(20-text.size-@pages[pagenum].size)
      text += @pages[pagenum]
      text[21] = '  ' + mess
      if (@pages.size > 1)
        text[22] = " page #{pagenum+1}/#{@pages.size}. "
        text[22] << case pagenum
        when 0
          "  Press down to scroll."
        when (@pages.size - 1)
          "  Press up to scroll."
        else
          "  Press up/down to scroll."
        end
      end
      text[23] = @bottomline
      text.map { |i| i.nil? ? '' : i }
      # puts "Text: #{@pages[pagenum]}"
      # exit
      BBS.clear
      BBS.print(text.join("\n"))
    end
    def run
      page = 0
      mess = "Please make a choice or (q)uit."
      oldval = BBS.echo
      BBS.echo = false
      loop do
        display_page(page,mess)
        choice = BBS.getch
        BBS.clear
        case choice
        when 'q'
          return
        when ' '
          BBS.safecall {
            @onspace.call
          }
          mess = "Please make a choice or (q)uit."
        when Curses::Key::DOWN
          page += 1 if page < (@pages.size - 1)
          mess = "Please make a choice or (q)uit."
        when Curses::Key::UP
          page -= 1 if page > 0
          mess = "Please make a choice or (q)uit."
        else
          if choice[0] >= ?r
            choice[0] -= 1
          end
          c = choice[0] - ?a
          if c >= 0 && @pagevals[page].size > c
            BBS.safecall {
              @block.call(@pagevals[page][c])
            }
            mess = "Please make a choice or (q)uit."
          else
            mess = "Invalid choice '#{choice}'. Please choose or (q)uit."
          end
        end
      end
    ensure
      BBS.echo = oldval
    end
  end
end
