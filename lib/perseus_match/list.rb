#--
###############################################################################
#                                                                             #
# A component of perseus_match, the fuzzy string matcher                      #
#                                                                             #
# Copyright (C) 2008-2012 Cologne University of Applied Sciences              #
#                         Claudiusstr. 1                                      #
#                         50678 Cologne, Germany                              #
#                                                                             #
# Copyright (C) 2013 Jens Wille                                               #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@gmail.com>                                       #
#                                                                             #
# perseus_match is free software: you can redistribute it and/or modify it    #
# under the terms of the GNU Affero General Public License as published by    #
# the Free Software Foundation, either version 3 of the License, or (at your  #
# option) any later version.                                                  #
#                                                                             #
# perseus_match is distributed in the hope that it will be useful, but        #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public      #
# License for more details.                                                   #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with perseus_match. If not, see <http://www.gnu.org/licenses/>.       #
#                                                                             #
###############################################################################
#++

class PerseusMatch

  class List < Array

    class << self

      def pair(phrases, pm_options = {}, list_options = {})
        phrases.uniq!

        pairs = [] unless block_given?

        unless list_options[:minimal]
          # => pairs.size = phrases.size ** 2

          phrases.each { |phrase|
            phrases.each { |target|
              pm = PerseusMatch.new(phrase, target, pm_options)
              block_given? ? yield(pm) : pairs << pm
            }
          }
        else
          # => pairs.size = (phrases.size ** 2 - phrases.size) / 2

          size = phrases.size

          1.upto(size) { |i|
            phrase = phrases[i - 1]

            i.upto(size - 1) { |j|
              pm = PerseusMatch.new(phrase, phrases[j], pm_options)
              block_given? ? yield(pm) : pairs << pm
            }
          }
        end

        pairs || phrases
      end

    end

    def initialize(phrases = [], pm_options = {}, list_options = {})
      self.class.pair(phrases, pm_options, list_options) { |pm| add(pm) }
    end

    alias_method :add, :push

  end

end
