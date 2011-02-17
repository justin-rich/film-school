class FilmDatabase::ActorsApp < FilmDatabase::Base
  
  configure do
    set :views, "app/views/actors"
  end
  
  helpers do
  end
  
  get '/' do
    @actors = Actor.all(:order => [:name])
    erb :index
  end
  
  get '/:id' do
    @actor = Actor.first(:netflix_id => params[:id])
    @films = @actor.films  
    erb :show
  end
  
end