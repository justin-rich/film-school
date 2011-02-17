class FilmDatabase::GenresApp < FilmDatabase::Base
  
  configure do
    set :views, "app/views/genres"
  end
  
  helpers do
  end

  get '/:id' do
    paginate
    @genre = Genre.first(:id => params[:id].split("-")[0])
    @films = @genre.films.all(:limit => @limit, :offset => (@page-1)*@limit, :order => [:title])
    erb :'../films/index', {:layout => :'../shared/layout'}
  end
end