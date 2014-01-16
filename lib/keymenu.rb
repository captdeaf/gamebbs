# menu.rb
#
# The menu class for the BBS module.

require 'text/format'

module BBS
  class KeyMenu
    attr_reader :bottomline
    def initialize(banner)
      fmt = Text::Format.new(banner)
      fmt.columns = 70
      fmt.body_indent = 6
      fmt.first_indent = 6
      @banner = fmt.format.split(/\n/)
      @banner << ''
      @choices = []
      @lkeys = []
      @keys = {}
      @keys['q'] = lambda { nil }
      @page = 0
      @pages = 0
      @bottomline = ''
      @onspace = lambda { true }
      build
    end
    def on_space(&block)
      @onspace = block
      @onspace ||= lambda { true }
    end
    def add_choice(key,text,&block)
      raise 'add_choice expects a block' unless block_given?
      raise 'quit is pre-defined!' if key == 'q'
      raise 'key must be one alphanumeric character' unless key =~ /^[a-zA-Z0-9]$/
      raise 'key must unique to the menu' if @keys.has_key?(key)
      fmt = Text::Format.new(text)
      fmt.columns = 50
      fmt.left_margin = 0
      fmt.body_indent = 0
      fmt.first_indent = 0
      rows = fmt.format.split(/\n/)
      rows[0] = "    #{key} - #{rows[0]}"
      rows[1] = "        #{rows[1]}" if rows.size > 1
      raise 'text for choice must fit in 2 lines' unless rows.size < 3
      @choices << rows
      @keys[key]  = block
      @lkeys << key
      build
    end
    def delete_choice(key)
      i = @lkeys.index(key)
      return unless i
      @choices.delete_at i
      @lkeys.delete_at i
      @keys.delete(i)
      build
    end
    def build
      maxrows = 19
      maxrows -= @banner.size
      # How many rows we have to work with.
      @pages = []
      rows = maxrows
      curpage = []
      @choices.each do |choice|
        case
        when rows < choice.size
          @pages << curpage
          curpage = []
          rows = maxrows
          curpage += choice
          rows -= choice.size
        else
          curpage += choice
          rows -= choice.size
        end
      end
      @pages << curpage
    end
    def display_page(pagenum,mess)
      text = [''] + @banner
      text += Array.new(20-text.size-@pages[pagenum].size)
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
        when Curses::Key::DOWN
          page += 1 if page < (@pages.size - 1)
          mess = "Please make a choice or (q)uit."
        when Curses::Key::UP
          page -= 1 if page > 0
          mess = "Please make a choice or (q)uit."
        else
          if @keys.has_key?(choice)
            BBS.safecall {
              @keys[choice].call
            }
            mess = "Please make a choice or (q)uit."
          else
            mess = "Invalid choice '#{choice.to_s.chomp}'. Please choose or (q)uit."
          end
        end
      end
    ensure
      BBS.echo = oldval
    end
  end
end
