# Generate Crossword and Findword puzzles. Ruby version of Python Crossword generator code.
# Find the original on http://bryanhelmig.com/python-crossword-puzzle-generator/
require 'date'
class Crossword
    attr_accessor :cols, :rows, :empty, :maxloops, :available_words, :grid, :current_word_list
    def initialize(cols, rows, empty = '-', maxloops = 2000, available_words=[])
        @cols = cols
        @rows = rows
        @empty = empty
        @maxloops = maxloops
        @available_words = available_words

        randomize_word_list

        @current_word_list = []
        @debug = 0

        clear_grid
    end
 
    def clear_grid() # initialize grid and fill with empty character
      @grid = []
      @rows.times do
        ea_row = []
        @cols.times do 
          ea_row << @empty
        end
        @grid << ea_row
      end
    end
 
    def randomize_word_list() # also resets words and sorts by length
        temp_list = []
        @available_words.each do |word|
          if word.instance_of?(Word)
              temp_list << Word.new(word.word, word.clue)
          else
              temp_list << Word.new(word[0], word[1])
          end
        end
        temp_list = temp_list.shuffle
        temp_list = temp_list.sort_by(&:length).reverse
        @available_words = temp_list
    end
 
    def compute_crossword(time_permitted = 1.00, spins=2)
        time_permitted = time_permitted.to_f
 
        count = 0

        copy = Crossword.new(@cols, @rows, @empty, @maxloops, @available_words)
        start_full = DateTime.now.strftime('%s').to_f
        while ((DateTime.now.strftime('%s').to_f - start_full) < time_permitted || count == 0) do# only run for x seconds
          @debug += 1
          copy.current_word_list = []
          copy.clear_grid()
          copy.randomize_word_list()
          x = 0
          while x < spins do # spins; 2 seems to be plenty
            copy.available_words.each do |word|
              unless copy.current_word_list.include?(word) # if word not in copy.current_word_list:
                copy.fit_and_add(word)
              end
            end
            x +=1
          end

          #print copy.solution()
          #print len(copy.current_word_list), len(@current_word_list), @debug
          # buffer the best crossword by comparing placed words
          if copy.current_word_list.length > @current_word_list.length
            @current_word_list = copy.current_word_list
            @grid = copy.grid
          end
          count +=1
        end
        return
    end
 
    def suggest_coord(word)
        count = 0
        coordlist = []
        glc = -1
        word.word.each_char do |given_letter|# cycle through letters in word
            glc += 1
            rowc = 0
            @grid.each do |row| # cycle through rows
                rowc += 1
                colc = 0
                row.each do |cell|# cycle through  letters in rows
                    colc += 1
                    if given_letter == cell # check match letter in word to letters in row
                        begin # suggest vertical placement 
                          if rowc - glc > 0 # make sure we're not suggesting a starting point off the grid
                            if ((rowc - glc) + word.length) <= @rows # make sure word doesn't go off of grid
                                coordlist << [colc, rowc - glc, 1, colc + (rowc - glc), 0]
                            end
                          end
                        rescue Exception => e
                            #nothing
                        end
                        begin # suggest horizontal placement 
                          if colc - glc > 0 # make sure we're not suggesting a starting point off the grid
                            if ((colc - glc) + word.length) <= @cols # make sure word doesn't go off of grid
                                coordlist << [colc - glc, rowc, 0, rowc + (colc - glc), 0]
                            end
                          end
                        rescue Exception => e
                            #nothing
                        end
                    end
                end
            end
        end
        # example: coordlist[0] = [col, row, vertical, col + row, score]
        #print word.word
        #print coordlist
        new_coordlist = sort_coordlist(coordlist, word)
        #print new_coordlist
        return new_coordlist
    end
 
    def sort_coordlist(coordlist, word) # give each coordinate a score, then sort
        new_coordlist = []
        coordlist.each do |coord|
            col = coord[0]
            row = coord[1]
            vertical = coord[2]
            coord[4] = check_fit_score(col, row, vertical, word) # checking scores
            if coord[4] != 0 # 0 scores are filtered
                new_coordlist << coord
            end
        end
        new_coordlist = new_coordlist.shuffle
        new_coordlist =  new_coordlist.sort_by { |i|  i[4] }
        new_coordlist = new_coordlist.reverse  # new_coordlist.sort(key=lambda i: i[4], reverse=True) # put the best scores first
        return new_coordlist
    end

    def fit_and_add(word) # doesn't really check fit except for the first word; otherwise just adds if score is good
        fit = false
        count = 0
        coordlist = suggest_coord(word)
        while (fit == false && count < @maxloops) do #  while not fit and count < @maxloops: OPTIMIZE
       
 
            if current_word_list.length == 0  # this is the first word: the seed
                # top left seed of longest word yields best results (maybe override)
                vertical = [0,1].sample 
                col = 1
                row = 1
                
                if check_fit_score(col, row, vertical, word)
                    fit = true
                    set_word(col, row, vertical, word, true)
                end
            else # a subsquent words have scores calculated
                begin 
                    col = coordlist[count][0]
                    row = coordlist[count][1]
                    vertical = coordlist[count][2]
                rescue Exception => e  #IndexError: return # no more cordinates, stop trying to fit OPTIMIZE
                    return
                end
 
                if coordlist[count][4] != 0 # already filtered these out, but double check
                    fit = true 
                    set_word(col, row, vertical, word, true)
                end
            end
 
            count += 1
        end
        return true
     end


    def check_fit_score(col, row, vertical, word)
        #And return score (0 signifies no fit). 1 means a fit, 2+ means a cross.
        #The more crosses the better.
        if col < 1 or row < 1
          return 0
        end
 
        count =  1 # give score a standard value of 1, will override with 0 if collisions detected
        score = 1
        word.word.each_char do |letter|
          begin
              active_cell = get_cell(col, row)
          rescue Exception => e # IndexError:
              return 0
          end
 
          if active_cell == @empty || active_cell == letter
              # NOTHING
          else
              return 0
          end
 
          if active_cell == letter
              score += 1
          end
          if vertical != 0
              # check surroundings
              if active_cell != letter # don't check surroundings if cross point
                  unless check_if_cell_clear(col+1, row) # check right cell
                      return 0
                  end
                  unless check_if_cell_clear(col-1, row) # check left cell
                      return 0
                  end
              end
 
              if count == 1 # check top cell only on first letter
                  unless check_if_cell_clear(col, row-1)
                      return 0
                  end
              end
 
              if count == word.word.length # check bottom cell only on last letter
                  unless check_if_cell_clear(col, row+1)
                      return 0
                  end
              end

          else # else horizontal
                # check surroundings
              if active_cell != letter # don't check surroundings if cross point
                  unless check_if_cell_clear(col, row-1) # check top cell
                      return 0
                  end
                  unless check_if_cell_clear(col, row+1) # check bottom cell
                      return 0
                  end
              end
 
              if count == 1 # check left cell only on first letter
                  unless check_if_cell_clear(col-1, row)
                      return 0
                  end
              end
 
              if count == word.word.length # check right cell only on last letter
                  unless check_if_cell_clear(col+1, row)
                      return 0
                  end
              end
          end
 
 
          if vertical != 0 # progress to next letter and position
              row += 1
          else # else horizontal
              col += 1
          end
 
          count += 1
        end
        return score
    end
 
    def set_word(col, row, vertical, word, force=false) # also adds word to word list
        if force
            word.col = col
            word.row = row
            word.vertical = vertical
            @current_word_list << word
            
            word.word.each_char do |letter|
                set_cell(col, row, letter)
                if vertical != 0
                    row += 1
                else
                    col += 1
                end
            end
        end
        return
    end
 
    def set_cell(col, row, value)
        @grid[row-1][col-1] = value
    end
 
    def get_cell(col, row)
        return @grid[row-1][col-1]
    end
 
    def check_if_cell_clear(col, row)
        begin
            cell = get_cell(col, row)
            if cell == @empty 
                return true
            end
        rescue Exception => e # IndexError:
            # pass
        end
        return false
    end
 
    def solution() # return solution grid
        outStr = ""
        @rows.times do |r| #for r in range(@rows):
            @grid[r].each do |c|
            
                outStr += "#{c} "
            end
            outStr += "\n"
        end
        return outStr
    end
 
    def word_find() # return solution grid OPTIMIZE
        outStr = ""
        @rows.times do |r|
            @grid[r].each do |c|
                if c == @empty
                    ran_char = ('a'..'z').to_a.sample
                    outStr += "#{ran_char} "
                else
                    outStr += "#{c} "
                end
            end

            outStr += "\n"
        end
        return outStr
    end
 
    def order_number_words() # orders words and applies numbering system to them
        @current_word_list.sort_by { |i| i.col + i.row}
        count = 1
        icount = 1
        @current_word_list.each do |word|
            word.number = count
            if icount < @current_word_list.length
                if word.col == @current_word_list[icount].col && word.row == @current_word_list[icount].row
                    # NOTHING
                else
                    count += 1
                end
            end
            icount += 1
        end
    end
 
    def display(order=true) # return (and order/number wordlist) the grid minus the words adding the numbers
        outStr = ""
        if order
            order_number_words
        end
 
        copy = self.clone #OPTIMiZE

        @current_word_list.each do |word|
            copy.set_cell(word.col, word.row, word.number)
        end
        
        copy.rows.times do |r|
            copy.grid[r].each do |c| 
                outStr += "#{c} "
            end
            outStr += "\n"
        end
        
        outStr = outStr.gsub(/[a-z]/, ' ')
        return outStr
    end
 
    def word_bank() 
        outStr = ''
        temp_list = @current_word_list.clone  # duplicate(@current_word_list)
        temp_list.shuffle
        temp_list.each do |word|
            outStr += "#{word.word}\n" # '%s\n' % word.word
        end
        return outStr
    end
 
    def legend() # must order first
        outStr = ''
        @current_word_list.each do |word|
            outStr +=  "#{word.number}. (#{word.col}, #{word.row}) #{word.down_across}: #{word.clue}\n"
        end
        return outStr
    end
end
 
class Word
    attr_accessor :word, :clue, :length, :row, :col, :vertical, :number
    def initialize(word=nil, clue=nil)
        @word = word.downcase.gsub(/\s/,'')
        @clue = clue
        @length = @word.length
        # the below are set when placed on board
        @row = nil
        @col = nil
        @vertical = nil
        @number = nil
    end
 
    def down_across() # return down or across
        if @vertical != 0
            return 'down'
        else 
            return 'across'
        end
    end
end