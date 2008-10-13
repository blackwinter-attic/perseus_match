#--
###############################################################################
#                                                                             #
# A component of perseus_match, the fuzzy string matcher                      #
#                                                                             #
# Copyright (C) 2008 Cologne University of Applied Sciences                   #
#                    Claudiusstr. 1                                           #
#                    50678 Cologne, Germany                                   #
#                                                                             #
# Authors:                                                                    #
#     Jens Wille <jens.wille@uni-koeln.de>                                    #
#                                                                             #
# perseus_match is free software: you can redistribute it and/or modify it    #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation, either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# perseus_match is distributed in the hope that it will be useful, but        #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License     #
# for more details.                                                           #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with perseus_match. If not, see <http://www.gnu.org/licenses/>.             #
#                                                                             #
###############################################################################
#++

class PerseusMatch

  class List < Array

    class << self

      def pair(phrases, pm_options = {})
        phrases.uniq!

        pairs = [] unless block_given?

        phrases.each { |phrase|
          phrases.each { |target|
            pm = PerseusMatch.new(phrase, target, pm_options)
            block_given? ? yield(pm) : pairs << pm
          }
        }

        pairs || phrases
      end

    end

    def initialize(phrases = [], pm_options = {})
      self.class.pair(phrases, pm_options) { |pm| add(pm) }
    end

    alias_method :add, :push

  end

end
