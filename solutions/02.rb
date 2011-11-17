class Song
  attr_reader :name, :artist, :genre, :subgenre, :tags

  def initialize name, artist, genre, subgenre, tags
    @name, @artist, @genre = name, artist, genre
		@subgenre, @tags = subgenre, Array(tags).map(&:downcase)
	  @tags.push genre.downcase
	  if subgenre != nil and subgenre != ""
	    @tags.push subgenre.downcase 
	  end
  end
  
  def fits? criteria
    criteria.all? { |crit| fits_single?(crit) }
  end
  
  def add_tags tags
    if tags.has_key? @artist
      @tags +=  Array(tags[@artist]).map(&:downcase)
    end
  end
  
  private
  
  def fits_single? crit
    case crit[0]
      when :name then @name == crit[1]
      when :artist then @artist == crit[1]
		  when :filter then crit[1].call(self)
		  when :tags
  		  Array(crit[1]).all? { |tag| has_tag?(tag) }
	  end
  end
  
  def has_tag? tag
    if tag.end_with? "!"
  	 return (not @tags.any? { |elem| elem == tag.chop.downcase })
  	end
  	@tags.any? { |elem| elem == tag.downcase }
  end
  
end

class Collection
  
  def initialize song_str, dict
    @song_str, @dict = song_str, dict
  	@song_arr = []
  	parse_str
  	if dict != {}
      @song_arr.cycle(1) { |song| song.add_tags(dict) }
	  end
  end
  
  def find criteria = {}
    if criteria == {} or criteria == nil
      return @song_arr
    end
    @song_arr.select { |song| song.fits?(criteria) }
  end
  
  private
  
  def parse_line line
    line_arr = line.split(".")
    name, artist = line_arr[0].strip, line_arr[1].strip
    genre_arr = line_arr[2].split(",").map(&:strip)
  	genre = genre_arr[0]
  	subgenre = genre_arr[1] == nil ? "" : genre_arr[1]
  	tags = line_arr[3] == nil ? [] : line_arr[3].split(",").map(&:strip)
  	@song_arr.push(Song.new(name, artist, genre, subgenre, tags))
  end
  
  def parse_str
    @song_str.lines { |line| parse_line(line.squeeze(" ").gsub(". ", ".")) }
  end

end