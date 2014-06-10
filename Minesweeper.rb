require 'yaml'
class Board
  attr_accessor :field, :num_revealed, :dimension
  def initialize(num_bomb, dimension)
    @dimension = dimension
    @num_bomb = num_bomb
    @num_revealed = 0
    @field = Array.new(dimension) do |row| 
      Array.new(dimension) { |col| Tile.new(self, [row, col]) }
    end
    make_bombs(num_bomb)
  end
  
  def won?
    return true if @num_revealed == ((@dimension ** 2) - @num_bomb)
    false
  end    
  
  def make_bombs(num_bomb)
    to_bomb = @field.flatten.sample(num_bomb)
    to_bomb.each { |tile| tile.bombed = true }
  end
  
  def to_s
    # label = "0 1 2 3 4 5 6 7 8"
    # puts label
    # puts    "-----------------"
    @field.map do |row|
      row.map { |tile| tile.to_s }.join(' ')
    end.join("\n")
  end
  
  def tile(row,col)
    @field[row][col]
  end
  
  # def [](pos)
#     row, col = pos
#     @field[row][col]
#   end
  
end

class Tile
  attr_accessor :bombed, :position, :reveal, :flag
  
  def initialize(board, position)
    @bombed = false
    @reveal = false
    @flag = false
    @position = position
    @board = board
  end
  
  def to_s
    return "F" if @flag
    return "*" unless @reveal
    return "_" if @reveal.zero?
    @reveal
  end  
  
  def explore
    @reveal = neighbor_bomb_count
    @board.num_revealed = @board.num_revealed + 1
    
    if neighbor_bomb_count.zero?
      neighbors.each do |neighbor|
         neighbor.explore unless neighbor.reveal
      end
    end
  end     
  
  def neighbors
    neighbors = []
    (-1..1).each do |x_mod|
      (-1..1).each do |y_mod|
        new_x = x_mod + @position[0]
        new_y = y_mod + @position[1]
        next if y_mod == 0 && x_mod == 0
        
        if new_x.between?(0, @board.dimension - 1) && 
          new_y.between?(0, @board.dimension - 1)
          neighbors << @board.tile(new_x, new_y) 
        end
      end
    end
    neighbors        
  end
  
  def neighbor_bomb_count
    neighbors.select {|neighbor| neighbor.bombed}.count
  end
  
end

class Highscores
  attr_accessor :scores
  def initialize
    @scores = []
  end

end


class Minesweeper
  def initialize(num_bomb, dimension) 
    if File.exists?("highscores.yaml")
      @highscores = YAML::load(File.open("highscores.yaml"))
    else
      @highscores = Highscores.new
    end
    @board = Board.new(num_bomb, dimension)
    @explode = false
  end
  
  def get_action(input)
    return nil if input.empty?
    tile = @board.tile(input[1].to_i, input[2].to_i)
    if input[0].upcase == "F"
      return if tile.reveal
      tile.flag = !tile.flag
    elsif input[0].upcase == "R"
      if tile.bombed
        @explode = true
        return
      else
        tile.explore
      end
    end   
  end

  def save
    File.open("minesweeper.yaml", "w") do |f|
      f.puts self.to_yaml
    end
  end
  
  def load
    YAML::load(File.open("minesweeper.yaml")).run
  end
    
  def run
    puts "high scores are: #{@highscores.scores}"
    start_time = Time.new
    until @explode || @board.won?
      puts @board.to_s
      puts "Select a tile"
      input = gets.chomp.upcase.split("")
      if input == ['I','E','D']
        break
      elsif input[0] == "L"
        load
        exit
      elsif input[0] == "S" 
        save
      else 
        get_action(input)
      end
    end
    if @explode 
      puts 'YOU LOSE'
    else
      total_time = Time.new - start_time
      puts "you won"
      if @highscores.scores.length > 4
        @highscores.scores.pop
      end
      @highscores.scores << total_time
      
      @highscores.scores = @highscores.scores.sort
      File.open("highscores.yaml","w") do |f|
        f.puts @highscores.to_yaml
      end     
    end
  end

end
     
if __FILE__ == $PROGRAM_NAME
  Minesweeper.new(10,9).run
end

