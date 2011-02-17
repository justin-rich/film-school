# Include required gems
%w{
  rubygems bundler
}.each {|req| require req }

Bundler.setup

%w{
  sinatra datamapper active_support 
  iconv timeout yaml hmac-sha1 json imdb curb
}.each {|req| require req }

# Require custom libraries and application files
Dir["lib/**/*.rb"].sort.each {|req| require req}

Settings = Configurator.load

# Global Logger
#Log = Logger.new(STDOUT)

DataMapper.setup(:default, {
  :adapter  => 'mysql',
  :host     => '127.0.0.1',
  :username => 'stripes' ,
  :password => 'XjLNRvE.:sPhWsWR',
  :database => 'films_development',
  :port     => 3306
})


# Require models and sinatra apps
Dir["app/models/**/*.rb"].sort.each {|req| require req}
Dir["app/apps/*.rb"].sort.each {|req| require req}



