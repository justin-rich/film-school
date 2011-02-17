class FilmGenre
  include DataMapper::Resource
    
  property :id,               Serial
  
  belongs_to :genre
  belongs_to :film
end