class Genre
  include DataMapper::Resource
    
  property :id,               Serial
  property :name,             String, :length => 255  
  
  has n, :film_genres
  has n, :films, :through => :film_genres
  
  def self.factory(attrs)
    return nil unless attrs[:name]
    existing = self.first(:name => attrs[:name])
    
    if existing
      existing
    else
      self.create(:name => attrs[:name])
    end
  end
  
  ##
  # Defines the format for using genre references in URLs
  #
  # @return String the URL slug of the genre name
  def to_param
    "#{self.id}-#{self.name.parameterize}"
  end
  
end