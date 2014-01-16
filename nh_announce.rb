#!/usr/bin/ruby
#
#

puts "This is deprecated."
exit

# Generic
require 'drb'

$announcer = nil
def announce(str)
  if $announcer.nil?
    DRb.start_service
    $announcer = DRbObject.new(nil,'druby://69.90.211.61:4343')
  end
  $announcer.announce(str)
end

$fem_expand = {
  'Cav'=>'Cavewoman',
  'Pri'=>'Priestess',
  'Hum Ran' => 'Daughter of Gondor',
  'Dwa Val' => 'Dwarf in a chain bikini',
  'Hum Val' => 'Chick in a chain bikini',
  'Hum Kni' => 'Maiden of the Round Table',
  'Hum Hea' => 'Florence Nightingale'
}

$expand = {
  'Hum Mon' => 'Monkey',
  'Hum Arc' => 'Indiana Jones Wannabe',
  'Hum Rog' => 'Politician',
  'Hum Wiz' => 'Raistlin worshipper',
  'Hum Tou' => 'Californian',
  'Elf Ran' => 'Legolas Fanfic Author',
  'Hum Ran' => 'Son of Gondor',
  'Hum Kni' => 'Knight of the Round Table',
  'Hum Cav' => 'B.C. Character',

  'Arc'=>'Archaeologist',
  'Bar'=>'Barbarian',
  'Cav'=>'Caveperson',
  'Fla'=>'Flame Mage',
  'Hea'=>'Healer',
  'Ice'=>'Ice Mage',
  'Kni'=>'Knight',
  'Mon'=>'Monk',
  'Nec'=>'Necromancer',
  'Pri'=>'Priest',
  'Rog'=>'Rogue',
  'Ran'=>'Ranger',
  'Sam'=>'Samurai',
  'Tou'=>'Tourist',
  'Und'=>'Undead Slayer',
  'Val'=>'Valkyrie',
  'Wiz'=>'Wizard',
  'Yeo'=>'Yeoman',

  'Dop'=>'Doppleganger',
  'Dro'=>'Drow',
  'Dwa'=>'Dwarf',
  'Elf'=>'Elf',
  'Gno'=>'Gnome',
  'Hob'=>'Hobbit',
  'Hum'=>'Human',
  'Lyc'=>'Lycanthrope',
  'Orc'=>'Orc',
  'Vam'=>'Vampire'
}

def do_announce(file,start,game)
  logs  = IO.readlines(file)
  return logs.size unless logs.size > start

  # 3.4.3 4560 0 4 5 37 55 0 20060913 20060913 7007 Hea Hum Fem Neu Oni,quit
  logs[start..logs.size].each do |line|
    line.chomp!
    version, points, something, dlevel, maxdlevel, curhp, maxhp, sumfin, start, finish, levels, cls, race, sex, align, name, death = line.split(/[\s,]/,17)
    levels =~ /(\d+)0(\d\d)/
    maxlevel = $1.to_i
    curlevel = $2.to_i

    lappend = ""
    if (maxlevel != curlevel)
      lappend = " (max #{maxlevel})"
    end

    racecls = case
    when sex == 'Fem' && $fem_expand.has_key?("#{race} #{cls}")
      $fem_expand["#{race} #{cls}"]
    when $expand.has_key?("#{race} #{cls}")
      $expand["#{race} #{cls}"]
    else
      race = $expand[race] if $expand.has_key?(race)
      cls = $expand[cls] if $expand.has_key?(cls)

      if sex =~ /fem/i
        race = $fem_expand[race] if $fem_expand.has_key?(race)
        cls = $fem_expand[cls] if $fem_expand.has_key?(cls)
      end
      "#{race} #{cls}"
    end

    name.gsub!(/\W/,'')
    death.gsub!(/ Conduct=\d+/,'')

    announce "#{game}: #{name}, #{racecls}, #{death} at level #{curlevel}#{lappend} with #{points} points."
  end
  return logs.size
end

NHLOG  = "/home/nethack/var/games/nethack/logfile"
$nh_count    = IO.readlines(NHLOG).size
$nh_curmtime = File.stat(NHLOG).mtime.to_i

def check_nethack
  return unless  File.stat(NHLOG).mtime.to_i > $nh_curmtime
  $nh_curmtime = File.stat(NHLOG).mtime.to_i
  $nh_count    = do_announce(NHLOG,$nh_count,"Nethack")
end

SELOG  = "/home/nethack/var/games/slashem/logfile"
$se_count    = IO.readlines(SELOG).size
$se_curmtime = File.stat(SELOG).mtime.to_i

def check_slashem
  return unless  File.stat(SELOG).mtime.to_i > $se_curmtime
  $se_curmtime = File.stat(SELOG).mtime.to_i
  $se_count    = do_announce(SELOG,$se_count,"Slash'em")
end

loop do
  sleep 5
  check_nethack
  check_slashem
end
