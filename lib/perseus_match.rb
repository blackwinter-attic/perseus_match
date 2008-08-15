#--
###############################################################################
#                                                                             #
# perseus_match -- Fuzzy string matching based on linguistic analysis         #
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

require 'perseus_match/list'
require 'perseus_match/cluster'
require 'perseus_match/token_set'

require 'perseus_match/version'

class PerseusMatch

  Infinity = 1.0 / 0

  DEFAULT_COEFF = 20

  DISTANCE_SPEC = {
    {}                   => 1,
    { :excl => %w[a t] } => 1,
    { :incl => 's'     } => 2,
    { :incl => 'y'     } => 4,
    { :sort => true    } => 4
  }

  class << self

    def match(phrases)
      List.new(phrases)
    end

    def cluster(phrases, options = {})
      Cluster.new(phrases).rank(options)
    end

  end

  attr_reader :phrase, :target, :distance_spec, :default_coeff

  def initialize(phrase, target, options = {})
    @phrase = phrase
    @target = target

    @default_coeff = options[:default_coeff] || DEFAULT_COEFF
    @distance_spec = options[:distance_spec] || DISTANCE_SPEC

    @similarity = {}
  end

  def phrase_tokens
    @phrase_tokens ||= tokenize(phrase)
  end

  def target_tokens
    @target_tokens ||= tokenize(target)
  end

  # 0 <= distance <= Infinity
  def distance
    @distance ||= calculate_distance
  end

  # 1 >= similarity >= 0
  def similarity(coeff = nil)
    coeff ||= default_coeff  # passed arg may be nil
    @similarity[coeff] ||= 1 / Math.exp(distance / (coeff * total_weight))
  end

  private

  def tokenize(str)
    TokenSet.new(str)
  end

  def calculate_distance
    return Infinity if phrase_tokens.disjoint?(target_tokens)
    return 0        if phrase_tokens == target_tokens

    distance_spec.inject(0) { |distance, (options, weight)|
      distance + token_distance(options) * weight
    }
  end

  def token_distance(options = {})
    phrase_tokens = self.phrase_tokens.inclexcl(options)
    target_tokens = self.target_tokens.inclexcl(options)

    if options[:sort]
      phrase_tokens.sort!
      target_tokens.sort!
    end

    (phrase_tokens.distance(target_tokens) + target_tokens.distance(phrase_tokens)) / 2.0
  end

  def total_weight
    distance_spec.values.inject(0.0) { |total, weight| total + weight }
  end

end
