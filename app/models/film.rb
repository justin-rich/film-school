class Film
  include DataMapper::Resource

  attr_accessor :netflix_movie

  property :id,               Serial
  property :title,            String, :length => 255
  property :year,             String, :length => 255
  property :written_by,       Text
  property :cinematographer,  Text
  property :genres_old,       String, :length => 255
  property :box_art_url,      String, :length => 255
  property :url,              Text
  property :description,      Text
  property :fulltext,         Text
  property :average_rating,   String, :length => 255
  property :predicted_rating, String, :length => 255
  property :actual_rating,    String, :length => 255
  property :average_rating,   String, :length => 255
  property :mpaa_rating,      String, :length => 255
  property :runtime,          String, :length => 255
  property :similars,         Text
  property :netflix_id,       String, :length => 255
  property :netflix_title,    String, :length => 255
  property :imdb_id,          String, :length => 255
  property :attempts,         Integer
  property :type,             Discriminator
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :directions
  has n, :directors, :through => :directions

  has n, :castings
  has n, :actors, :through => :castings

  has n, :film_genres
  has n, :genres, :through => :film_genres

  ##
  # Film factory - Creates or updates a Film
  #
  # @example Create a film
  #  Film.factory(
  #             :title => 'Title of film',
  #             :year => '2000'
  #           )
  #
  # @param [Hash] attrs the default attrs to create or update an Article with
  # @option attrs [String] :search the search term to use to find the film (required)
  # @option attrs [String] :year the year the film was made (required)
  #
  # @return [Article] the newly created or updated article
  def self.factory(attrs)
    return nil unless attrs[:title] && attrs[:year]

    film = first(:title => attrs[:title], :year => attrs[:year])

    default_attrs = {
      :attempts => film && film.attempts ? film.attempts + 1 : 1
    }

    attrs = attrs.merge(default_attrs)

    if film # If the film already exists
      if film.fulltext.blank? && film.attempts < 2
        film.import
      end

      film
    else # Otherwise, create a new film
      new_film = self.new(attrs)
      new_film.save
      new_film.import
    end
  end

  def self.netflix_id_factory(netflix_id, save_record=true)
    film = Film.first(:netflix_id => netflix_id)
    return film if film

    new_film = self.new(:netflix_id => netflix_id)
    new_film.import
  end

  ##
  # Netflix autocomplete search wrapper
  #
  # @return [String] the array of matching titles
  def self.autocomplete_search(query)
    Netflix::Movie.autocomplete_search(query)
  end

  ##
  # Netflix search wrapper
  #
  # @return [Film]
  def self.search(query)
    movies = Netflix::Movie.search(query)

    movies.collect do |m|
      self.new(
        :netflix_id => m.netflix_id,
        :title => m.title,
        :year => m.release_year,
        :box_art_url => m.box_art_large
      )
    end
  end

  ##
  #
  def self.update_netflix_ratings
    limit = 20

    (0..1000).each do |offset|
      films = self.all(:netflix_id.not => nil, :limit => limit, :offset => offset)

      netflix_ids = films.map {|f| f.netflix_id}

      ratings = Netflix::Rating.all(netflix_ids)

      ratings.each do |rating|
        f = self.first(:netflix_id => rating.netflix_id)
        f.update(:actual_rating => rating.value)
      end

      return true if films.size < limit
    end
  end

  def self.find_netflix_movie(netflix_id, title=nil, year=nil)
    return nil unless (netflix_id || (title && year))

    if netflix_id
      Netflix::Movie.find(netflix_id)
    else
      movies = Netflix::Movie.search(title)

      return nil if movies.empty?

      movie = movies.detect {|m| m.title == title && m.release_year == year}

      return nil if movie.nil?

      Netflix::Movie.find(movie.netflix_id)
    end
  end

  def self.sync
    films = `ls /Volumes/Nil/Movies`.split("\n")

    remove_ext = /(.*)\s+\((\d{4})\)(\..{3,3})/
    remove_pt = /(\s+Pt\. \d{1,2}(\s+\&\s+\d{1,2})*)?/

    films = films.map {|m| m.gsub(remove_ext, "#{$1} (#{$2})")}.map {|m| m.gsub(remove_pt, "")}.uniq
    films.delete(" ()")

    films.each do |film|
      begin
        parts = film.split("(")
        title = parts[0].strip
        year = parts[1].chop

        p title

        f = Film.factory(:title => title, :year => year)

        f.set_as_available_film if f
      rescue Exception => e
        p e
        p e.backtrace
      end
    end
  end

  ##
  # Sets the film's attributes in the database to a combination of screen-scraped and given attributes
  #
  # @param [Hash] attrs the given attributes for the film
  #
  # @return [Film] the film with newly scraped attributes
  def import
    set_netflix_movie

    return nil if self.netflix_movie.nil?

    netflix = get_movie_information_from_netflix

    # Set the title here if it isn't already set as a prerequisite for searching IMDB
    self.title = netflix[:title] if self.title.nil?
    
    # Ignore all films that are bonus material for another film
    return nil if /bonus/i.match(self.title)

    imdb = get_movie_information_from_imdb

    self.attributes = netflix.merge(imdb)

    get_directors.each do |director|
      self.directors << director
    end

    get_cast.each do |actor|
      self.actors << actor
    end

    self.save

    self
  end

  def update_from_netflix
    netflix = get_movie_information_from_netflix
    self.update(netflix)
    self
  end

  def update_from_imdb
    imdb = get_movie_information_from_imdb
    self.update(imdb)
    self
  end

  ##
  # Retrieves the actual rating for the film from Netflix
  #
  # @return [String, nil] the actual rating value or nil if there is no actual rating
  def get_actual_rating
    rating = Netflix::ActualRating.first(self.netflix_id)

    if rating
      rating.value
    else
      nil
    end
  end
  
  ##
  # Representation of film in URLs for the web-application
  def to_param
    self.netflix_id
  end

  ##
  # Updates the film's rating on Netflix to the given rating
  #
  # @param [String] _actual_rating the rating to pass to Netflix for the film
  #
  # @return [Netflix::ActualRating, nil] if the new rating is the same as the old returns nil
  def set_actual_rating(_actual_rating)
    return nil if _actual_rating.nil? || self.rating == _actual_rating
    self.actual_rating = "#{_actual_rating.to_i}.0"
    self.save
    Netflix::ActualRating.create_or_update(self.netflix_id, self.actual_rating)
  end

  ##
  # Updates the film's actual rating in the database to the actual rating in Netflix
  def update_actual_rating
    self.actual_rating = self.get_actual_rating
    self.save
  end

  ##
  # Retrieves the predicted rating for the film from Netflix
  #
  # @return [String, nil] the predicted rating value or nil if there is no predicted rating
  def get_predicted_rating
    rating = Netflix::PredictedRating.first(self.netflix_id)

    if rating
      rating.value
    else
      nil
    end
  end

  ##
  # The rating for the film is the actual rating, if it exists, and the predicted rating otherwise
  #
  # @return [String] the best rating according to Netflix
  def rating
    self.actual_rating ? self.actual_rating : self.predicted_rating
  end

  ##
  # Retrieves the film's information from Netflix
  #
  # @return [Netflix::Movie]
  def get_netflix_movie
    Film.find_netflix_movie(self.netflix_id, self.title, self.year)
  end

  def set_as_available_film
    adapter = DataMapper.repository(:default).adapter
    adapter.execute("UPDATE `films` SET type = 'AvailableFilm' WHERE `netflix_id` = #{self.netflix_id}")
  end

  ##
  # Box art image URL hosted by Netflix
  #
  # @param [String] size - possible values are "small", "large" & "gsd"
  #
  # @return [String] the URL for the sized image with a default size of large
  def box_art(size)
    self.box_art_url.gsub("large", size)
  end
  
  ##
  # Retrieves a set of similar films according to Netflix
  #  NOTE: this will import several movies on-demand if necessary
  #
  # @return [Array<Film>] the similar films
  def similar_films
    return [] if [Film, TemporaryFilm].include?(self.type)
    self.similars.split(", ").inject([]) do |films, netflix_id|
      film = TemporaryFilm.netflix_id_factory(netflix_id)

      if film
        films << film
      else
        films
      end
    end
  end

  private

  ##
  # Parses the film's attributes from Netflix
  def get_movie_information_from_netflix
    {
      :title          => self.title.blank? ? get_netflix_title : self.title,
      :netflix_title  => get_netflix_title,
      :year           => get_release_year,
      :genres_old     => get_genres,
      :netflix_id     => get_netflix_id,
      :box_art_url    => get_box_art_url,
      :description    => get_description,
      :fulltext       => get_description,
      :average_rating => get_average_rating,
      :mpaa_rating    => get_mpaa_rating,
      :runtime        => get_runtime,
      :similars       => get_similars
    }
  end

  def get_netflix_title
    self.netflix_movie.title
  end

  def get_release_year
    self.netflix_movie.release_year
  end

  def get_genres
    self.netflix_movie.genres.join(", ")
  end

  def get_netflix_id
   self.netflix_movie.netflix_id
  end

  def get_box_art_url
    self.netflix_movie.box_art_large
  end

  def get_directors
    directors = self.netflix_movie.directors

    if directors.is_a?(Array)
      directors.map {|d| Director.factory(d)}
    elsif directors.nil?
      []
    else
      [Director.factory(directors)]
    end
  end

  def get_description
    self.netflix_movie.synopsis
  end

  def get_average_rating
    self.netflix_movie.average_rating
  end

  def get_cast
    actors = self.netflix_movie.cast

    if actors.is_a?(Array)
      actors.map {|a| Actor.factory(a)}
    elsif actors.nil?
      []
    else
      [Actor.factory(actors)]
    end
  end

  def get_mpaa_rating
    self.netflix_movie.mpaa_rating
  end

  def get_runtime
    self.netflix_movie.runtime
  end

  def get_similars
    self.netflix_movie.similars.map {|movie| movie.netflix_id}.join(", ")
  end

  def set_netflix_movie
    begin
      self.netflix_movie = self.get_netflix_movie
    rescue Exception => e
      p e
      nil
    end
  end

  def get_movie_information_from_imdb
    return {} if self.title.blank?

    movies = IMDB::Movie.search(self.title)

    if movies.is_a?(Array) && !movies.empty?
      imdb_id = movies.first.id
      credits = IMDB::Movie.new(movies.first.id).credits

      {:imdb_id => imdb_id}.merge(credits)
    else
      {}
    end
  end
end

class AvailableFilm < Film
  def set_as_available_film
    true
  end  
end

class SavedFilm < Film
end

class TemporaryFilm < Film
  def set_as_wanted_film
    adapter = DataMapper.repository(:default).adapter
    adapter.execute("UPDATE `films` SET type = 'SavedFilm' WHERE `netflix_id` = #{self.netflix_id}")
  end
end