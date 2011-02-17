module Netflix
  # This class represents a rating (director, castmember, etc) in the Netflix catalog
  class PredictedRating < Base
    attr_accessor :url, :netflix_id, :value

    def self.title_url_base
      "http://api.netflix.com/catalog/titles/movies"
    end

    def self.all(netflix_ids)      
      title_refs = netflix_ids.map {|netflix_id| "#{title_url_base}/#{netflix_id}"}.join(",")

      params   = {:title_refs => title_refs}      
      response = protected_request "GET", "users/#{self.userid}/ratings/title/predicted", params
      parse_many(response)
    end

    def self.first(netflix_id)
      ratings = all([netflix_id])
      ratings.empty? ? nil : ratings.first
    end

    protected
    # Parses a response xml string for people.
    def self.parse_many(body) # :nodoc:
      xml = Hash.from_xml(body)
      results = xml["ratings"]["ratings_item"]

      results = results ? results.delete_if {|r| r == nil} : []

      if results.is_a?(Hash) # one results
        rating = instantiate results
        [rating]
      else # many results
        results.map { |result| instantiate result }
      end
    end

    def self.instantiate(entry={})
      PredictedRating.new(:url => entry['id'],
        :netflix_id => entry['id'].split('/').last,
        :value => entry['predicted_rating'])
    end
  end
  
  # This class represents a rating (director, castmember, etc) in the Netflix catalog
  class ActualRating < Base
    attr_accessor :url, :netflix_id, :value
    
    def self.title_url_base
      "http://api.netflix.com/catalog/titles/movies"
    end
    
    def self.all(netflix_ids)      
      title_refs = netflix_ids.map {|netflix_id| "#{title_url_base}/#{netflix_id}"}.join(",")
      
      params   = {:title_refs => title_refs}      
      response = protected_request "GET", "users/#{self.userid}/ratings/title/actual", params
      parse_many(response)
    end
    
    def self.first(netflix_id)
      ratings = all([netflix_id])
      ratings.empty? ? nil : ratings.first
    end
    
    def self.create(netflix_id, rating)    
      title_ref = "#{title_url_base}/#{netflix_id}"
      params   = {:title_ref => title_ref, :rating => rating.to_i}
      protected_request "POST", "users/#{self.userid}/ratings/title/actual", params
    end
    
    def self.update(netflix_id, rating)
      params   = {:rating => rating.to_i}
      protected_request "PUT", "users/#{self.userid}/ratings/title/actual/#{netflix_id}", params
    end
    
    def self.create_or_update(netflix_id, rating)
      if first(netflix_id)
        update(netflix_id, rating)
      else
        create(netflix_id, rating)
      end
    end
      
    protected
    # Parses a response xml string for people.
    def self.parse_many(body) # :nodoc:
      xml = Hash.from_xml(body)
      results = xml["ratings"]["ratings_item"]
      
      results = results ? results.delete_if {|r| r == nil} : []
      
      if results.is_a?(Hash) # one results
        rating = instantiate results
        [rating]
      else # many results
        results.map { |result| instantiate result }
      end
    end

    def self.instantiate(entry={})
      ActualRating.new(:url => entry['id'],
        :netflix_id => entry['id'].split('/').last,
        :value => entry['user_rating'])
    end
  end
end