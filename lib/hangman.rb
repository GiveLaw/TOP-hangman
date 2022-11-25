class Hangman
  require 'json'
  DIR = 'saved_games'

  def initialize
    reset
  end

  def run
    loop {menu}
  end

  def play
    return if @word.empty?

    hangman_alive = %{

           ┏━━━━━━━━━━━━┯╸ Help me!
           ┃            │ ╱
           ┃             ‿
           ┃         ╺─╼╋╾╯
           ┃            ┃
           ┃            ║
           ┃            ║
           ┃        ┌┈┈┈╨┈┈┈┈┐
           ┃        ┊        ┊
           ┃        ┊        ┊
           ┃        ┊        ┊
      ━━━━━┻━━━━━━━━┷━━━━━━━━┷━━━

    }
    hangman_dead = %{

           ┏━━━━━━━━━━━━┯╸ You failed me!
           ┃            │ ╱
           ┃            
           ┃          _◞╋◟◞
           ┃          ◟ ┃
           ┃◟           ║     ◟
           ┃    ◟       ║  ◞
           ┃         ◞  ╹
           ┃
           ┃                 ◞
           ┃   ◞
      ━━━━━┻━━━━━━━━━━━━━━━━━━━━━

    }
    hangman_win = %{

           ┏━━━━━━━━━━━━┯╸ Good job!
           ┃            ⸾ ╱
           ┃          ╲  ╱
           ┃           ╹╋╹
           ┃            ┃
           ┃           ╱ ╲
           ┃          ╱   ╲
           ┃        ┌┈┈┈┈┈┈┈┈┐
           ┃        ┊        ┊
           ┃        ┊        ┊
           ┃        ┊        ┊
      ━━━━━┻━━━━━━━━┷━━━━━━━━┷━━━

    }

    @attempts.times do |attempt|
      system 'clear'

      puts hangman_alive
      puts "\tRemaining attempts #{@attempts}"
      puts %{\tcurrent:
        #{@guess.join ' '}
      }

      print "\tGuess Guessing:  "
      input = gets.chomp.strip.downcase
      return if input == ''
      check input
      @attempts -= 1
      break if @guess == @word
    end

    if @word == @guess then puts hangman_win
    else puts hangman_dead end

    puts "\t#{@word.join}"

    delete_file
    reset

    puts '
    Press enter to continue...'
    gets  # simplicity is perfection :>
  end

  def check input
    if input.length == 1 && @word.include?(input)
      @word.each_with_index do |char, index|
        @guess[index] = char if char == input
      end
    elsif input == @word.join then @guess = input.split ''
    end
  end

  def give_up
    return if @word.empty?

    system 'clear'
    show 'LOSER!'
    puts %{
      Word: #{@word.join}

      This tutorial may help you:
        https://youtu.be/LLFhKaqnWwk
    }
    delete_file
    reset
    puts '
    Press enter to continue...'
    gets  # simplicity is perfection :>
  end

  def reset
    @word = []
    @guess = []
    @attempts = 0
    @file_name = nil
  end

  def new_game
    system 'clear'

    save_game

    @word = File.open('filtered_words.txt') do |file|
      file.readlines.sample.chomp.downcase.split ''
    end
    @guess = Array.new(@word.length, '⎽')
    @attempts = @word.length * 2
    @file_name = nil

    show 'New Game!'
  end

  def save?
    unless @file_name
      system 'clear'

      show 'This game has not yet been saved'
      print "\tSave? <y/n> [y]  "

      case gets.chomp.strip.downcase
      when ''  then true
      when 'y' then true
      when 'n' then false
      else save?
      end
    end
  end

  def save_game
    system 'clear'

    if @file_name then fn = @file_name
    elsif @word.any? && save?
      fn = "#{@word.length}_chars - (#{Time.now.ctime})"
    else return
    end

    File.open("#{DIR}/#{fn}.json", 'w') do |file|
      file.puts JSON.dump({
        word: @word.join,
        guess: @guess.join,
        attempt: @attempts,
      })
      @file_name = File.basename file, '.json'
    end

    show 'Saved!'
  end

  def load_game
    save_game

    list = Dir.glob '*.json', base: DIR

    if list.empty?
      show 'No game to be Loaded!'
      return
    end

    loop do
      system 'clear'
      show 'LOAD'

      list.each_with_index do |file, index|
        puts "\t#{index+1}\t#{File.basename file, '.json'}"
      end

      print "\n\tType the 'index'  "
      index = gets.chomp.strip

      return if index == ''
      index = index.to_i - 1
      next unless index.between? 0, list.length

      File.open("#{DIR}/#{list[index]}") do |file|
        data = JSON.load file.read
        @word = data['word'].split ''
        @guess = data['guess'].split ''
        @file_name = File.basename file, '.json'
        @attempts = data['attempt']
      end

      break
    end

    show 'Loaded!'
    play
  end

  def delete_file
    if File.exist? "#{DIR}/#{@file_name}.json"
      File.delete "#{DIR}/#{@file_name}.json"
    end
  end

  def menu
    system 'clear'

    show 'MENU'
    print %{
      1 - New
      2 - Save
      3 - Load
      4 - Give Up (for losers)
      5 - Exit
      }

     case gets.chomp.strip
     when ''  then play
     when '1' then new_game; play
     when '2' then save_game; play
     when '3' then load_game
     when '4' then give_up
     when '5'
      # the only important code here is 'exit'...
      save_game
      show 'BYE'
      puts %{

    ╭─┬─╮ ╭───╮ ╭───┬─╮ ╭───╮ ╭───┬───╮ ╭───╮ ╭───┬─╮
    │ │ │ │ ╷ │ │ ╷ │ │ │ ╭─┤ │ ╷ │ ╷ │ │ ╷ │ │ ╷ │ │
    │   │ │   │ │ │ │ │ │ │ │ │ │ │ │ │ │   │ │ │ │ │
    │ │ │ │ │ │ │ │ ╵ │ │ ╵ │ │ │ ╵ │ │ │ │ │ │ │ ╵ │
    ╰─┴─╯ ╰─┴─╯ ╰─┴───╯ ╰───╯ ╰─┴───┴─╯ ╰─┴─╯ ╰─┴───╯
    
    ╭─╮                                  
    │ ╰─╮╭───╮╭─┬─╮╭───╮╭─┬─┬─╮╭───╮╭─┬─╮
    │   │├── ││   ││ ╷ ││     │├── ││   │
    │ │ ││ · ││ │ ││   ││ │ │ ││ · ││ │ │
    ╰─┴─╯╰───╯╰─┴─╯├─╮ │╰─┴─┴─╯╰───╯╰─┴─╯
                   ╰───╯                 

      }
      sleep 1
      system 'reset'
      exit
     end
  end

  def show msg
    puts " #{msg} ".center 60, '─'
  end
end

# ----------- here the magic begins
system 'reset'

puts %{

    ╭─╮╭─╮ ╭────╮ ╭───┬─╮ ╭────╮ ╭───┬───╮ ╭────╮ ╭───┬─╮
    │ ╰╯ │ │ ╭╮ │ │ ╷ │ │ │ ╭──┤ │ ╷ │ ╷ │ │ ╭╮ │ │ ╷ │ │
    │    │ │ ╰╯ │ │ │ │ │ │ ├╮ │ │ │ │ │ │ │ ╰╯ │ │ │ │ │
    │ ╭╮ │ │ ╭╮ │ │ │ ╵ │ │ ╰╯ │ │ │ ╵ │ │ │ ╭╮ │ │ │ ╵ │
    ╰─╯╰─╯ ╰─╯╰─╯ ╰─┴───╯ ╰────╯ ╰─┴───┴─╯ ╰─╯╰─╯ ╰─┴───╯

    This is the Hangman Game
    Check this link to learn more about the game:
      https://en.wikipedia.org/wiki/Hangman_(game)

    <ENTER> key is for cancel, go to the menu or go back
    to the game in case you're in one.

    The file that saves the game will be deleted at the
    end of the game, for logistical reasons :)

    press <enter> to start...
}

system 'clear' if gets  # simplicity is perfection :>

game = Hangman.new
game.run