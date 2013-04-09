#--
###############################################################################
#                                                                             #
# perseus_match -- Fuzzy string matching based on linguistic analysis         #
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

require 'perseus_match/core_ext'

require 'perseus_match/list'
require 'perseus_match/cluster'
require 'perseus_match/token'
require 'perseus_match/token_set'

require 'perseus_match/version'

class PerseusMatch

  Infinity = 1.0 / 0

  DEFAULT_COEFF = 2

  DISTANCE_SPEC = [                # {
    [{},                      1],  #   {}                      => 1,
    [{ :excl    => %w[a t] }, 2],  #   { :excl    => %w[a t] } => 1,
    [{ :incl    => 's'     }, 3],  #   { :incl    => 's'     } => 2,
    [{ :incl    => 'y'     }, 4],  #   { :incl    => 'y'     } => 4,
    [{ :sort    => true    }, 4],  #   { :sort    => true    } => 4,
    [{ :soundex => true    }, 4]   #   { :soundex => true    } => 8
  ]                                # }

  class << self

    def distance(*args)
      new(*args).distance
    end

    def match(phrases, pm_options = {})
      List.new(phrases, pm_options)
    end

    def cluster(phrases, options = {}, pm_options = {})
      Cluster.new(phrases, pm_options).rank(options)
    end

    def check(*args)
      check!(*args)
    rescue CheckFailedError
      false
    end

    def check!(phrase, target, threshold = 0, operator = :>, pm_options = {}, attribute = :similarity)
      pm = new(phrase, target, pm_options)
      value = pm.send(attribute)

      if value.send(operator, threshold)
        Struct.new(:pm, :value, :threshold, :operator).new(pm, value, threshold, operator)
      else
        raise CheckFailedError.new(pm, value, threshold, operator)
      end
    end

    def tokenize(form, unknowns = false)
      if file = TokenSet.file?(form)
        TokenSet.tokenize(file, unknowns)
      else
        PhraseTokenSet.tokenize(form, unknowns)
      end
    end

  end

  attr_reader :phrase, :target, :distance_spec, :default_coeff, :verbose

  def initialize(phrase, target, options = {})
    @phrase = sanitize(phrase.to_s)
    @target = sanitize(target.to_s)

    @default_coeff = options[:default_coeff] || DEFAULT_COEFF
    @distance_spec = options[:distance_spec] || DISTANCE_SPEC

    @verbose = options[:verbose]

    @similarity = {}
  end

  def phrase_tokens
    @phrase_tokens ||= self.class.tokenize(phrase)
  end

  def target_tokens
    @target_tokens ||= self.class.tokenize(target)
  end

  # 0 <= distance <= Infinity
  def distance
    @distance ||= calculate_distance
  end

  # 1 >= similarity >= 0
  def similarity(coeff = nil)
    coeff ||= default_coeff  # passed arg may be nil
    @similarity[coeff] ||= normalize_distance(coeff)
  end

  private

  def sanitize(str)
    str.gsub(/\s*\(.*?\)|\s*\[.*?\]/, '').sub(/\s*[\/:].*/, '')
  end

  def calculate_distance
    return Infinity if phrase_tokens.disjoint?(target_tokens)
    return 0        if phrase_tokens.eql?(target_tokens)

    distance_spec.inject(0) { |distance, (options, weight)|
      distance + token_distance(options) * weight
    }
  end

  def token_distance(options = {})
    tokens1 = phrase_tokens.inclexcl(options)
    tokens2 = target_tokens.inclexcl(options)

    if options[:sort]
      tokens1 = tokens1.sort
      tokens2 = tokens2.sort
    end

    if options[:soundex]
      tokens1 = tokens1.soundex
      tokens2 = tokens2.soundex
    end

    distance = tokens1.distance(tokens2)

    warn <<-EOT if verbose
#{options.inspect}:
  #{tokens1.inspect}
  #{tokens2.inspect}
=> #{distance}
    EOT

    distance
  end

  def normalize_distance(coeff)
    length = phrase_tokens.size + target_tokens.size
    return 0 if length == 0

    norm = Math.log(length ** Math.sqrt(2)) * coeff * total_weight * Math::E

    1 / Math.exp(distance / norm)
  end

  def total_weight
    @total_weight ||= distance_spec.inject(0.0) { |total, (_, weight)| total + weight }
  end

  class CheckFailedError < StandardError

    attr_reader :pm, :value, :threshold, :operator

    def initialize(pm, value, threshold, operator)
      @pm, @value, @threshold, @operator = pm, value, threshold, operator
    end

    def to_s
      "FAILED: #{value} #{operator} #{threshold}"
    end

  end

end
