module Netflix
  class Error < StandardError; end
end

module Netflix
  class Base
    
    #-----------------
    # Class Methods
    #-----------------
  
    class << self
      cattr_accessor :host, :protocol, :base_url, :debug, :consumer_key, :consumer_secret, :token_secret, :oauth_version, :retry_times, :userid, :oauth_token, :oauth_token_secret
      
      def http_request(method="GET", url='')
        begin
          response = nil
          extra_data = method == "PUT" ? ",\"\"" : ""                                   
          seconds = Benchmark.realtime { response = eval("Curl::Easy.http_#{method.downcase}(url#{extra_data})")}
          puts "  \e[4;36;1m#{method} REQUEST (#{sprintf("%f", seconds)})\e[0m   \e[0;1m#{url}\e[0m"# if debug
          response.is_a?(String) ? response : response.body_str
        rescue => e
          puts "  \e[4;36;1mERROR\e[0m   \e[0;1m#{url}\e[0m"# if debug
          raise e
        end
      end
      
      # Non-Authenticated Calls (Consumer Key Only)
      def non_authenticated_request(method="GET", path="/", params={})
        params[:oauth_consumer_key] = consumer_key
        url = "#{base_url}/#{path}?#{params.to_param.gsub("+", "%20")}"
        http_request(method, url)        
      end

      # Signed Requests (Consumer Key plus Signature)
      def signed_request(method="GET", path="/", params={})
        params[:oauth_consumer_key]     ||= consumer_key
        params[:oauth_nonce]            ||= nonce
        params[:oauth_signature_method] ||= "HMAC-SHA1"
        params[:oauth_timestamp]        ||= Time.now.to_i + 5
        params[:oauth_version]          ||= oauth_version

        oauth_params = params.to_param.gsub("+", "%20") # per oauth, automagically alphabetizes the params
        oauth_base_string = "#{e method}&#{e base_url}#{e '/'}#{e path}&#{e oauth_params}"
        signature = Base64.encode64(HMAC::SHA1.digest(signed_secrets, oauth_base_string)).chomp.gsub(/\n/,'')
        url = "#{base_url}/#{path}?#{params.to_param.gsub("+", "%20")}&oauth_signature=#{e signature}"

        http_request(method, url)
      end
      
      # Protected Requests (Consumer Key, Signature, and Access Token)
      def protected_request(method="GET", path="/", params={})
        params[:oauth_consumer_key]     ||= consumer_key
        params[:oauth_nonce]            ||= nonce
        params[:oauth_signature_method] ||= "HMAC-SHA1"
        params[:oauth_timestamp]        ||= Time.now.to_i + 5
        params[:oauth_version]          ||= oauth_version
        params[:oauth_token]            ||= self.oauth_token

        oauth_params = params.to_param.gsub("+", "%20") # per oauth, automagically alphabetizes the params
        oauth_base_string = "#{e method}&#{e base_url}#{e '/'}#{e path}&#{e oauth_params}"
        signature = Base64.encode64(HMAC::SHA1.digest(protected_secrets, oauth_base_string)).chomp.gsub(/\n/,'')
        url = "#{base_url}/#{path}?#{params.to_param.gsub("+", "%20")}&oauth_signature=#{e signature}"

        http_request(method, url)
      end

    
      protected
        def e(str)
          CGI.escape(str)
        end

        def nonce
          rand(1_500_000_000)
        end

        def signed_secrets
          "#{e consumer_secret}&" 
        end
        
        def protected_secrets
          "#{e consumer_secret}&#{e oauth_token_secret}"           
        end

        def settings
          @settings ||= YAML.load(File.open(File.dirname(__FILE__)+'/../../config/netflix.yml'))
        end
    end
  
    # These are the default settings for the Base class. Change them, even per subclass if needed.
    self.host = "api.netflix.com"
    self.protocol = "http"
    self.base_url = "#{protocol}://#{host}" # just a shortcut
    self.oauth_version = 1.0
    self.consumer_key = settings['key'].strip
    self.consumer_secret = settings['secret'].strip
    self.userid = settings['userid'].strip
    self.oauth_token = settings['oauth_token'].strip
    self.oauth_token_secret = settings['oauth_token_secret']
    self.debug = true if ENV['DEBUG']
    self.retry_times = 0

    #-----------------
    # Instance Methods
    #-----------------
    def initialize(values={})
      values.each { |k, v| send "#{k}=", v }
    end

    # Copied from ActiveRecord::Base
    def attribute_for_inspect(attr_name)
      value = send(attr_name)

      if value.is_a?(String) && value.length > 50
        "#{value[0..50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_s(:db)}")
      else
        value.inspect
      end
    end
  end
end
