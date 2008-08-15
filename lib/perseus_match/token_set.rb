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

$KCODE = 'u'

LINGO_BASE = '/home/jw/devel/lingo/trunk'

LINGO_CONFIG = {
  'meeting' => {
    'attendees' => [
      { 'textreader'   => { 'files'=> 'STDIN' } },
      { 'tokenizer'    => {  } },
      { 'wordsearcher' => { 'source' => 'sys-dic', 'mode' => 'first' } },
      { 'decomposer'   => { 'source' => 'sys-dic' } },
      { 'multiworder'  => { 'source' => 'sys-mul', 'stopper' => 'PUNC,OTHR' } },
      { 'synonymer'    => { 'source' => 'sys-syn', 'out' => 'syn', 'skip'=>'?,t' } },
      { 'debugger'     => { 'prompt' => '', 'eval' => 'true', 'ceval' => 'false' } }
    ]
  }
}

require 'tempfile'
require 'yaml'

# use enhanced Tempfile#make_tmpname, as of r13631
if RUBY_RELEASE_DATE < '2007-10-05'
  class Tempfile

    def make_tmpname(basename, n)
      case basename
      when Array
        prefix, suffix = *basename
      else
        prefix, suffix = basename, ''
      end

      t = Time.now.strftime("%Y%m%d")
      path = "#{prefix}#{t}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}#{suffix}"
    end

  end
end
 
class PerseusMatch

  class TokenSet < Array

    def self.tokenize(form)
      return @tokens[form] if @tokens

      @_tokens = {}
      @tokens  = Hash.new { |h, k| h[k] = new(
        k, @_tokens.has_key?(k) ? @_tokens[k] :
          k.scan(/\w+/).map { |i| @_tokens[i] }.flatten.compact
      )}

      parse = lambda { |x|
        x.each { |res|
          case res
            when /<(.*?)\s=\s\[(.*)\]>/
              a, b = $1, $2
              @_tokens[a.sub(/\|.*/, '')] ||= b.scan(/\((.*?)\+?\)/).flatten
            #when /<(.*)>/, /:(.*):/
            #  # ignore
          end
        }
      }

      if File.readable?(t = 'perseus.tokens')
        File.open(t) { |f| parse[f] }
        @tokens[form]
      else
        cfg = Tempfile.new(['perseus_match_lingo', '.cfg'])
        YAML.dump(LINGO_CONFIG, cfg)
        cfg.close

        file = form[0] == ?/ ? form : File.join(Dir.pwd, form)

        unless File.file?(file) && File.readable?(file)
          temp = Tempfile.new('perseus_match_temp')
          temp.puts form
          temp.close

          file = temp.path
        end

        Dir.chdir(LINGO_BASE) { parse[%x{
          ./lingo.rb -c #{cfg.path} < #{file}
        }] }

        cfg.unlink

        if temp
          temp.unlink

          tokens, @tokens = @tokens[form], nil
          tokens
        else
          @tokens[form]
        end
      end
    end

    private :push, :<<, :[]=  # maybe more...

    attr_reader :form

    def initialize(form, tokens = nil)
      super(tokens || self.class.tokenize(form))

      @form   = form
      @tokens = to_a.flatten
    end

    def distance(other)
      distance, index, max = xor(other).size, -1, size

      intersect(other).each { |token|
        while current = other.tokens[index += 1] and current != token
          distance += 1

          break if index > max
        end
      }

      distance
    end

    def tokens(wc = true)
      wc ? @tokens : @tokens_sans_wc ||= @tokens.map { |token|
        token.sub(%r{[/|].*?\z}, '')
      }
    end

    def &(other)
      tokens & other.tokens
    end

    def |(other)
      tokens | other.tokens
    end

    def intersect(other)
      (self & other).inject([]) { |memo, token|
        memo + [token] * [count(token), other.count(token)].max
      }
    end

    def xor(other)
      ((self | other) - (self & other)).inject([]) { |memo, token|
        memo + [token] * (count(token) + other.count(token))
      }
    end

    def disjoint?(other)
      (tokens(false) & other.tokens(false)).empty?
    end

    def inclexcl(inclexcl = {})
      incl(inclexcl[:incl] || '.*').excl(inclexcl[:excl])
    end

    def incl(*wc)
      (@incl ||= {})[wc = [*wc].compact] ||= map { |tokens|
        tokens.reject { |token| !match?(token, wc) }
      }.to_token_set(form)
    end

    def excl(*wc)
      (@excl ||= {})[wc = [*wc].compact] ||= map { |tokens|
        tokens.reject { |token| match?(token, wc) }
      }.to_token_set(form)
    end

    def count(token)
      counts[token]
    end

    def counts
      @counts ||= tokens.inject(Hash.new(0)) { |counts, token|
        counts[token] += 1
        counts
      }
    end

    def inspect
      "#{super}<#{form}>"
    end

    alias_method :to_s, :inspect

    private

    def match?(token, wc)
      token =~ %r{[/|](?:#{wc.join('|')})\z}
    end

  end

  class ::Array

    def to_token_set(form)
      TokenSet.new(form, self)
    end

  end

end
