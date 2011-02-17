class Direction
  include DataMapper::Resource
    
  property :id,               Serial
  property :created_at,       DateTime
  property :updated_at,       DateTime  
  
  belongs_to :director
  belongs_to :film
end