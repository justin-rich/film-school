module FilmDatabase
  # Setup sinatra configuration
  class Base < Sinatra::Base
    configure do
      use Rack::Session::Cookie, 
        :secret => 'I will cut you up and stuff you in a mattress like drug money.'
      set :raise_errors, false
      set :dump_errors, true
      set :methodoverride, true
      set :show_exceptions, false
      set :static, true
      set :root, Settings.root
    end
    
    helpers do
      def partial(page, locals={})
        erb(page, {:layout => false}, locals)
      end
      
      def paginate
        @limit = params[:limit] ? params[:limit].to_i : 28
        @page = params[:page] ? params[:page].to_i : 1
      end
      
      def numColumns(items)
        word = case items
        when 1
          "one"
        when 2
          "two"
        when 3
          "three"
        when 4
          "four"
        when 5
          "five"
        when 6
          "six"
        else
          "seven"
        end

        "#{word}Columns"
      end

      def imgSize(numItems)
        case 
        when numItems < 5
          "gsd"
        else 
          "large"
        end
      end
    end
    
    not_found do
      "Not Found"
    end
    
    error do
      "Error"
    end
    
    before do
      serve_mobile
    end
    
    def set_content_type
      if params[:format]
        request.env["HTTP_ACCEPT"] = 'application/json'
      end
    end

    def serve_mobile
      self.content_type = :mobile if is_mobile_device?
    end

    MOBILE_USER_AGENTS =  'palm|palmos|palmsource|iphone|blackberry|nokia|phone|midp|mobi|pda|' +
                          'wap|java|nokia|hand|symbian|chtml|wml|ericsson|lg|audiovox|motorola|' +
                          'samsung|sanyo|sharp|telit|tsm|mobile|mini|windows ce|smartphone|' +
                          '240x320|320x320|mobileexplorer|j2me|sgh|portable|sprint|vodafone|opwv|' +
                          'mot-|sec-|lg-|sie-|up.b|up/'

    def is_mobile_device?
      request.user_agent.to_s.downcase =~ Regexp.new(MOBILE_USER_AGENTS)
    end
  end
end