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

require 'pathname'
require 'rbconfig'
require 'tempfile'
require 'yaml'

begin
  require 'rubygems'
  require 'text/soundex'
rescue LoadError
  warn "could not load the Text gem -- soundex functionality will not be available"
end

LINGO_BASE = ENV['PM_LINGO_BASE'] ||
  File.readable?('LINGO_BASE') && File.read('LINGO_BASE').chomp

LINGO_FOUND = File.readable?(File.join(LINGO_BASE, 'lingo.rb'))
warn "lingo installation not found at #{LINGO_BASE} -- proceeding anyway" unless LINGO_FOUND

LINGO_CONFIG = if File.readable?(file = ENV['PM_LINGO_CONFIG'] || 'lingo.cfg')
  config = YAML.load_file(file)

  config['meeting']['attendees'].unshift(
    { 'textreader' => { 'files'=> 'STDIN' } }
  )

  config['meeting']['attendees'].push(
    { 'debugger' => { 'prompt' => '', 'eval' => 'true', 'ceval' => 'false' } }
  )

  config
else
  warn "lingo config not found at #{ENV['PM_LINGO_CONFIG']} -- using default" if ENV.has_key?('PM_LINGO_CONFIG')

  {
    'meeting' => {
      'attendees' => [
        { 'textreader'   => { 'files'=> 'STDIN' } },
        { 'tokenizer'    => {  } },
        { 'wordsearcher' => { 'source' => 'sys-dic', 'mode' => 'first' } },
        { 'decomposer'   => { 'source' => 'sys-dic' } },
        { 'multiworder'  => { 'source' => 'sys-mul', 'stopper' => 'PUNC,OTHR' } },
        { 'synonymer'    => { 'source' => 'sys-syn', 'skip' => '?,t' } },
        { 'debugger'     => { 'prompt' => '', 'eval' => 'true', 'ceval' => 'false' } }
      ]
    }
  }
end

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
            when /<(.*)>/, /:(.*):/
              a, b = $1, $1.dup
              @_tokens[a.sub!(/[\/|].*/, '')] ||= b

              warn "UNK: #{a} [#{res.strip}]" if b =~ /\|\?\z/
          end
        }
      }

      if File.readable?(t = 'perseus.tokens')
        File.open(t) { |f| parse[f] }
        @tokens[form]
      else
        raise "lingo installation not found at #{LINGO_BASE}" unless LINGO_FOUND

        cfg = Tempfile.new(['perseus_match_lingo', '.cfg'])
        YAML.dump(LINGO_CONFIG, cfg)
        cfg.close

        file = Pathname.new(form).absolute? ? form : File.join(Dir.pwd, form)

        unless File.file?(file) && File.readable?(file)
          temp = Tempfile.new('perseus_match_temp')
          temp.puts form
          temp.close

          file = temp.path
        end

        begin
          Dir.chdir(LINGO_BASE) { parse[%x{
            #{Config::CONFIG['ruby_install_name']} lingo.rb -c "#{cfg.path}" < "#{file}"
          }] }
        ensure
          cfg.unlink
          temp.unlink if temp
        end

        if temp
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

    def distance(other, weight = 1)
      tokens1, tokens2 = tokens, other.tokens
      size1, size2 = tokens1.size, tokens2.size

      return size2 if tokens1.empty?
      return size1 if tokens2.empty?

      # make sure size1 <= size2, to use O(min(size1, size2)) space
      if size1 > size2
        tokens1, tokens2 = tokens2, tokens1
        size1, size2 = size2, size1
      end

      costs, fill = (0..size1 + 1).to_a, [0] * size1

      0.upto(size2) { |index2|
        token2, previous, costs = tokens2[index2], costs, [index2 + 1, *fill]

        0.upto(size1) { |index1|
          penalty = token2 == tokens1[index1] ? 0 : weight

          # rcov hack :-(
          _ = [
            previous[index1 + 1] + 1,   # insertion
            costs[index1] + 1,          # deletion
            previous[index1] + penalty  # substitution
          ]
          costs[index1 + 1] = _.min
        }
      }

      costs[size1] + xor(other).size
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
      (@incl ||= {})[wc = [*wc].compact] ||= select { |token|
        match?(token, wc)
      }.to_token_set(form)
    end

    def excl(*wc)
      (@excl ||= {})[wc = [*wc].compact] ||= reject { |token|
        match?(token, wc)
      }.to_token_set(form)
    end

    def soundex
      raise "soundex functionality not available" unless defined?(Text::Soundex)

      @soundex ||= map { |token|
        token.sub(/(.*)(?=[\/|])/) { |m| Text::Soundex.soundex(m) }
      }.to_token_set(form)
    end

    def soundex!
      replace soundex
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
