class PerseusMatch

  class List < Array

    alias_method :add, :push

    def initialize(phrases = [])
      if phrases.is_a?(self.class)
        phrases.each { |pm| add(pm) }
      else
        phrases.uniq!

        phrases.each { |phrase|
          phrases.each { |target|
            add(PerseusMatch.new(phrase, target))
          }
        }
      end
    end

  end

end
