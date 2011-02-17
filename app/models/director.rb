class Director
  include DataMapper::Resource
  
  attr_accessor :netflix_director
  
  property :id,               Serial
  property :name,             String, :length => 255
  property :bio,              Text
  property :filmography,      Text
  property :netflix_id,       String, :length => 255
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :directions
  has n, :films, :through => :directions, :order => [ :year.asc ]

  ##
  # Director factory - Creates or updates a Director
  #
  # @example Create a director
  #  Director.factory(
  #             :name => 'Name of director',
  #           )
  #
  # @param [Netflix::Person] person the netflix person representing the director
  #
  # @return [Director] the newly created or updated director
  def self.factory(person)
    return nil unless person
    
    director = first(:netflix_id => person.netflix_id)
    
    if director # If the director  already exists
      director  
    else # Otherwise, create a new film
      new_director = self.new
      new_director.import(person)
    end        
  end 
  

  # Defines the format for using director references in URLs
  #
  # @return String the URL slug of the film title
  def to_param
    "#{self.id}-#{self.name.parameterize}"
  end
  
  ##
  # Sets the film's attributes in the database to a combination of screen-scraped and given attributes
  # 
  # @param [Hash] attrs the given attributes for the director
  #
  # @return [Director] the director with newly scraped attributes
  def import(person)
    set_netflix_director(person)
  
    return nil if self.netflix_director.nil?
  
    self.attributes = get_director_information_from_netflix
    self
  end
  
  private
  
  ##
  # Parses the film's attributes from Netflix
  def get_director_information_from_netflix
    {
      :name         => get_name,
      :bio          => get_bio,
      :filmography  => get_filmography,
      :netflix_id   => get_netflix_id
    }
  end
  
  def get_name
    self.netflix_director.name
  end
  
  def get_bio
    self.netflix_director.bio
  end
  
  def get_filmography
    filmography = self.netflix_director.filmography
  
    if filmography.is_a?(Array)
      filmography.map {|f| f.netflix_id}.join(", ")
    elsif filmography.nil?
      ''
    else
      filmography.netflix_id
    end
  end
  
  def get_netflix_id
    self.netflix_director.netflix_id
  end
  
  def set_netflix_director(director)
    self.netflix_director = director
  end
end