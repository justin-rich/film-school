module Netflix
  class Award
    attr_accessor :award_url, :award_name, :category, :recipient, :year
    def initialize(entry)
      self.award_url  = entry["category"]["scheme"] # http://api.netflix.com/categories/award_types/academy_awards
      self.award_name = award_url.split('/').last   # academy_awards TODO parse correctly
      self.category   = entry["category"]["label"]  # Best Supporting Actor
      self.recipient  = entry["link"]["title"]      # Heath Ledger TODO parse robustly? 
      self.year       = entry["year"]               # 2009
    end
  end
end