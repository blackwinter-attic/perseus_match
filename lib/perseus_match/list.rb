class PerseusMatch

  class List < Array

    class << self

      def pair(phrases)
        if phrases.is_a?(self)
          phrases.each { |pm| yield pm }
        else
          phrases.uniq!

          phrases.each { |phrase|
            phrases.each { |target|
              yield PerseusMatch.new(phrase, target)
            }
          }
        end
      end

    end

    alias_method :add, :push

    def initialize(phrases = [])
      self.class.pair(phrases) { |pm| add(pm) }
    end

  end

end
