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

  class Cluster < Hash

    def initialize(phrases = [])
      super() { |h, k| h[k] = [] }

      List.new(phrases).each { |pm| add(pm) }
    end

    def add(pm)
      self[pm.phrase] << pm
    end

    alias_method :<<, :add

    def sort_by(attribute, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}

      _ = map { |phrase, matches|
        res = {}

        matches = matches.sort_by { |match|
          res[match] = match.send(attribute, *args)
        }

        # premise: if any is, then all are (i.e., only first needs checking)
        numeric = res.any? { |_, r| break r.is_a?(Numeric) }

        # sort numeric results in reverse order
        matches.reverse! if numeric

        if threshold = options[:threshold]
          condition = numeric ?
            lambda { |match| res[match] < threshold } :
            lambda { |match| res[match] > threshold }

          matches.reject! { |match| condition[match] }
        end

        if limit = options[:limit]
          matches.slice!(limit..-1)
        end

        # transform entries if so requested
        matches.map!(&block) if block

        [phrase, matches]
      }.sort

      _  # rcov hack :-(
    end

    def sort(options = {}, &block)
      sort_by(:similarity, options.delete(:coeff), options, &block)
    end

    def rank(options = {})
      coeff = options[:coeff]
      sort(options) { |match| [match.target, match.similarity(coeff)] }
    end

  end

end
