class Actor
  include DataMapper::Resource
  
  attr_accessor :netflix_actor
  
  property :id,               Serial
  property :name,             String, :length => 255  
  property :bio,              Text
  property :netflix_id,       Integer
  property :filmography,      Text
  property :created_at,       DateTime
  property :updated_at,       DateTime  
  
  has n, :castings
  has n, :films, :through => :castings, :order => [ :year.asc ]
  
  ##
  # Actor factory - Creates or updates a Actor
  #
  # @example Create a actor
  #  Actor.factory(
  #             Netflix::Person.find(netflix_id)
  #           )
  #
  # @param [Netflix::Person] person the netflix person representing the actor
  #
  # @return [Actor] the newly created or updated actor
  def self.factory(person)
    return nil unless person
    
    actor = first(:netflix_id => person.netflix_id)
    
    if actor # If the actor already exists
      actor  
    else # Otherwise, create a new film
      new_actor = self.new
      new_actor.import(person)
    end        
  end
  
  ##
  # Actor syncing will complete each actor's filmography in a slow fashion
  def self.sync
  end
  
  # Defines the format for using actor references in URLs
  #
  # @return String the URL slug of the film title
  def to_param
    "#{self.netflix_id}"
  end
  
  ##
  # Sets the film's attributes in the database to a combination of screen-scraped and given attributes
  # 
  # @param [Hash] attrs the given attributes for the director
  #
  # @return [Director] the director with newly scraped attributes
  def import(person)
    set_netflix_actor(person)
  
    return nil if self.netflix_actor.nil?
  
    self.attributes = get_actor_information_from_netflix
    self
  end
  
  private
  
  ##
  # Parses the film's attributes from Netflix
  def get_actor_information_from_netflix
    {
      :name         => get_name,
      :bio          => get_bio,
      :filmography  => get_filmography,
      :netflix_id   => get_netflix_id
    }
  end
  
  def get_name
    self.netflix_actor.name
  end
  
  def get_bio
    self.netflix_actor.bio
  end
  
  def get_filmography
    # filmography = self.netflix_actor.filmography
    #   
    # if filmography.is_a?(Array)
    #   filmography.map {|f| f.netflix_id}.join(", ")
    # elsif filmography.nil?
    #   ''
    # else
    #   filmography.netflix_id
    # end
  end
  
  def get_netflix_id
    self.netflix_actor.netflix_id
  end
  
  def set_netflix_actor(actor)
    self.netflix_actor = actor
  end
end