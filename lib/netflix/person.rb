module Netflix
  # This class represents a person (director, castmember, etc) in the Netflix catalog
  class Person < Base
    attr_accessor :netflix_id, :url, :name, :bio, :filmography_url, :webpage_url

    class << self
      # Search for all people with a query. [undocumented in Netflix api]
      #
      # ==== Attributes
      #
      # * +term+ - The word or term for which to search in the catalog. 
      # * +options+ - 
      #    * <tt>:page/tt> - the page number of results; 20 shown at a time (default is 1, per_page is required) 
      #    * <tt>:per_page</tt> - the maximum number of results to return. This number cannot be greater than 100. 
      #                           If max_results is not specified, the default value is 25.
      #
      # ==== Examples
      #
      #   Netflix::Person.search('mifune')
      #   > [[#<Netflix::Person:0x1882358>, ... ]
      def search(term, options={})
        options.symbolize_keys!

        params                   = {}
        params[:term]            = URI.escape term
        params[:start_index]     = ((options[:page] - 1) * 20) if options[:page]
        params[:max_results]     = options[:per_page] if options[:per_page]

        response = signed_request "GET", "catalog/people", params
        
        raise Error, "No people found!" if response.nil? || response.empty?
        parse_many response
      end

      # Find a person by their Netflix ID.
      def find(netflix_id)
        response = signed_request "GET", "catalog/people/#{netflix_id}"
        raise Error, "Person not found!" if response.nil? || response.empty?
        parse_one response
      end
      
      protected
      # Parses a response xml string for people.
      def parse_many(body) # :nodoc:
        clean_body = Iconv.iconv("ascii//translit", "UTF-8", body).join
        
        xml = Hash.from_xml(clean_body)
        results = xml["people"]["person"]
        if results.is_a?(Hash) # one results
          instantiate results
        else # many results
          results.map { |result| instantiate result }
        end
      end
      
      # Parses a response xml string for person.
      def parse_one(body) # :nodoc:
        xml = Hash.from_xml(body)
        instantiate xml["person"]
      end

      def instantiate(entry={})
        Person.new(:url => entry['id'],
          :netflix_id => entry['id'].split('/').last,
          :name => entry['name'],
          :webpage_url => (entry['link'].find { |l| l['title'] == 'web page' }['href'] rescue nil),
          :filmography_url => (entry['link'].find { |l| l['title'] == 'filmography' }['href'] rescue nil),
          :bio => entry['bio'])
      end
    end
    
    # Returns a list of the Movie items that are under this person's filmography.
    def filmography
      return @filmography if @filmography
      response = self.class.signed_request "GET", "catalog/people/#{@netflix_id}/filmography"
      @filmography = Hash.from_xml(response) ["filmography"]["filmography_item"].map { |m| 
        Movie.send(:instantiate, m) 
      } rescue nil
    end
    
  end
end

