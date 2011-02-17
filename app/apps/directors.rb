class FilmDatabase::DirectorsApp < FilmDatabase::Base
  
  configure do
    set :views, "app/views/directors"
  end
  
  helpers do
  end
  
  get '/' do
    @directors = Director.all(:order => [:name])
    erb :index
  end
  
  get '/:id' do
    @director = Director.first(:id => params[:id].split("-")[0])
    @films = @director.films
    erb :show
  end
end