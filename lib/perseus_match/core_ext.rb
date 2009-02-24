require 'rubygems'
require 'unicode'

class String

  def downcase
    Unicode.downcase(self)
  end

  def downcase!
    replace downcase
  end

end
