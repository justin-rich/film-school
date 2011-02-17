## Handy method for removing HTML tags from content
class String
  def strip_html(allow = [])
    allow_arr = allow.join('\\b|') << '|/'
    tag_pat = %r,<(?:(?:/?)|(?:\s*)).*?>,
    self.gsub(tag_pat, '').strip
  end  
  
  def transliterate
    Iconv.iconv('ascii//ignore//translit', 'utf-8', self).to_s      
  end  
  
  def random
    
  end
end