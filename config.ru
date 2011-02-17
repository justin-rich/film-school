require 'init'

map "/" do
	run FilmDatabase::FilmsApp
end

map "/directors" do
	run FilmDatabase::DirectorsApp
end

map "/actors" do
	run FilmDatabase::ActorsApp
end

map "/genres" do
	run FilmDatabase::GenresApp
end