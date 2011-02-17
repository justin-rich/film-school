class FilmDatabase::FilmsApp < FilmDatabase::Base
    
  configure do
    set :views, "app/views/films"
  end
  
  helpers do
    ##
    # Updates the film's actual rating in the database to the predicted rating in Netflix
    def ensure_film_has_predicted_rating(film)
      return nil if film.predicted_rating
      film.predicted_rating = film.get_predicted_rating
      film.save
    end
    
    ##
    # For the jquery star rating plugin; each of the 5 stars are broken into 5 parts
    # increasing in value in increments of 0.2 e.g. 1.0, 1.4, 1.6, 1.8 . This
    # function will round down the given film's actual rating to the closest value
    # represented by the star rating system
    def display_rating_value(film)
      left, right = film.rating.split(".").map {|part| part.to_i}
      right%2 == 0 ? "#{left}.#{right}" : "#{left}.#{right-1}"
    end
    
    def pass_the_popcorn_url(title)
      "http://passthepopcorn.me/torrents.php?filter_cat%5B1%5D=1&searchstr=#{URI.encode(title)}"
    end
  end
  
  get '/' do
    paginate
    @films = AvailableFilm.all(:netflix_id.not => nil, :limit => @limit, :offset => (@page-1)*@limit, :order => [:title])
    erb :index
  end
  
  get '/want-to-watch' do
    paginate
    @films = SavedFilm.all(:netflix_id.not => nil, :order => [:title], :limit => @limit, :offset => (@page-1)*@limit)
    erb :index
  end
  
  post '/want-to-watch' do
    content_type :json    
    @film = TemporaryFilm.netflix_id_factory(params[:netflix_id])
    @film.set_as_wanted_film
    {:response => "200", :url => "/search/#{@film.to_param}"}.to_json
  end
  
  post '/search' do
    paginate
    @films = TemporaryFilm.search(params[:query])
    erb :index
  end
  
  get '/search/:netflix_id' do    
    @film = TemporaryFilm.netflix_id_factory(params[:netflix_id])
    erb :show
  end
  
  get '/autocomplete' do
    content_type :json        
    @titles = Film.autocomplete_search(params[:term])
    @titles.to_json
  end
  
  get '/ratings/:netflix_id' do
    content_type :json
    @film = Film.first(:netflix_id => params[:netflix_id])
    # ensures the film has at least one rating to return
    ensure_film_has_predicted_rating(@film)
    {:rating => display_rating_value(@film)}.to_json
  end
  
  post '/ratings' do
    @film = Film.first(:netflix_id => params[:netflix_id])
    
    rating = params[:rating] ? "#{params[:rating].split(".")[0]}.0" : nil
    
    @film.set_actual_rating(rating)
    {:response => "ok"}.to_json
  end
  
  get '/fate' do
    erb :fate
  end
  
  get '/point-blank' do
    erb :point_blank
  end
end