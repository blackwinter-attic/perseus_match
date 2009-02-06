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

$KCODE = 'u' unless RUBY_VERSION >= '1.9'

require 'pathname'
require 'rbconfig'
require 'yaml'

require 'rubygems'
require 'backports/tempfile'
require 'nuggets/tempfile/open'
require 'nuggets/util/i18n'

begin
  require 'text/soundex'
rescue LoadError
  warn "Could not load the Text gem -- Soundex functionality will not be available"
end

LINGO_BASE = ENV['PM_LINGO_BASE'] || (
  File.readable?('LINGO_BASE') ? File.read('LINGO_BASE').chomp : '.'
)

if LINGO_FOUND = File.readable?(File.join(LINGO_BASE, 'lingo.rb'))
  begin
    require File.join(LINGO_BASE, 'lib', 'const')
  rescue LoadError
  end
else
  warn "Lingo installation not found at #{LINGO_BASE} -- proceeding anyway"
end

unless Object.const_defined?(:PRINTABLE_CHAR)
  PRINTABLE_CHAR = '[\w-]'
end

PRINTABLE_CHAR_RE = %r{(?:#{PRINTABLE_CHAR})+}

lingo_config = if File.readable?(file = ENV['PM_LINGO_CONFIG'] || 'lingo.cfg')
  YAML.load_file(file)
else
  warn "Lingo config not found at #{ENV['PM_LINGO_CONFIG']} -- using default" if ENV.has_key?('PM_LINGO_CONFIG')

  {
    'meeting' => {
      'attendees' => [
        { 'tokenizer'    => {  } },
        { 'wordsearcher' => { 'source' => 'sys-dic', 'mode' => 'first' } },
        { 'decomposer'   => { 'source' => 'sys-dic' } },
        { 'multiworder'  => { 'source' => 'sys-mul', 'stopper' => 'PUNC,OTHR' } },
        { 'synonymer'    => { 'source' => 'sys-syn', 'skip' => '?,t' } },
      ]
    }
  }
end

lingo_config['meeting']['attendees'].
  unshift({ 'textreader' => { 'files'=> 'STDIN' } }).
  push({ 'debugger' => { 'prompt' => '', 'eval' => 'true', 'ceval' => 'false' } })

LINGO_CONFIG = lingo_config

class PerseusMatch

  class TokenSet < Array

    class << self

      def tokenize(form, unknowns = false)
        return @tokens[form] if @tokens ||= nil

        @_tokens = Hash.new
        @tokens  = Hash.new { |h, k| h[k] = new(k, @_tokens[k] || []) }

        tokens_file = ENV['PM_TOKENS_FILE'] || 'perseus.tokens'

        if File.readable?(tokens_file)
          File.open(tokens_file) { |f| parse(f, unknowns, @_tokens) }
          @tokens[form]
        else
          raise "Lingo installation not found at #{LINGO_BASE}" unless LINGO_FOUND

          cfg = Tempfile.open(['perseus_match_lingo', '.cfg']) { |t|
            YAML.dump(LINGO_CONFIG, t)
          }

          file = file?(form) || begin
            temp = Tempfile.open('perseus_match_temp') { |t| t.puts form }
            temp.path
          end

          ruby = Config::CONFIG.values_at('RUBY_INSTALL_NAME', 'EXEEXT').join

          if keep = ENV['PM_KEEP_TOKENS']
            keep = File.expand_path(keep =~ /\A(?:1|y(?:es)?|true)\z/i ? tokens_file : keep)
          end

          begin
            Dir.chdir(LINGO_BASE) {
              tokens = %x{#{ruby} lingo.rb -c "#{cfg.path}" < "#{file}"}
              File.open(keep, 'w') { |f| f.puts tokens } if keep
              parse(tokens, unknowns, @_tokens)
            }
          ensure
            cfg.unlink
            temp.unlink if temp
          end

          if temp
            tokens, @tokens = @tokens[form], nil
            tokens
          end
        end
      end

      def file?(form)
        file = Pathname.new(form).absolute? ? form : File.expand_path(form)
        file if File.file?(file) && File.readable?(file)
      end

      private

      def parse(output, unknowns = false, tokens = {})
        output.each_line { |res|
          case res
            when /<(.*?)\s=\s\[(.*)\]>/
              a, b = $1, $2
              a.sub!(Token::WC_RE, '')

              tokens[a] ||= b.scan(/\((.*?)\+?\)/).flatten.map { |t| Token.new(t) }
            when /<(.*)>/, /:(.*):/
              a, b = $1, Token.new($1.replace_diacritics.downcase)
              a.sub!(Token::WC_RE, '')

              if unknowns && b.unk?
                if unknowns.respond_to?(:<<)
                  unknowns << a
                else
                  warn "UNK: #{a} [#{res.strip}]"
                end
              end

              tokens[a] ||= [b]
          end
        }

        tokens
      end

    end

    private :push, :<<, :[]=  # maybe more...

    attr_reader :form, :tokens

    def initialize(form, tokens = nil)
      super(tokens || self.class.tokenize(form))

      @form   = form
      @tokens = to_a
    end

    def distance(other)
      self == other ? 0 : 1  # TODO
    end

    def forms
      @forms ||= map { |token| token.form }
    end

    def disjoint?(other)
      (forms & other.forms).flatten.empty?
    end

    def inclexcl(inclexcl = {})
      incl(inclexcl[:incl] || Token::ANY_WC).excl(inclexcl[:excl])
    end

    def incl(wcs)
      self.class.new(form, select { |token| token.match?(wcs) })
    end

    def excl(wcs)
      self.class.new(form, reject { |token| token.match?(wcs) })
    end

    def soundex
      ensure_soundex!

      @soundex ||= self.class.new(form, map { |token|
        form = token.form.replace_diacritics.sub(/\W+/, '')
        Token.new(Text::Soundex.soundex(form), token.wc)
      })
    end

    def ==(other)
      tokens == other.tokens
    end

    def eql?(other)
      self == other && form == other.form
    end

    def inspect
      "#{super}<#{form}>"
    end

    alias_method :to_s, :inspect

    private

    def ensure_soundex!
      unless defined?(Text::Soundex)
        raise RuntimeError, "Soundex functionality not available", caller(1)
      end
    end

  end

  class PhraseTokenSet < TokenSet

    class << self

      def tokenize(form, unknowns = false)
        (@tokens ||= {})[form] ||= new(form, form.scan(PRINTABLE_CHAR_RE).map { |i|
          TokenSet.tokenize(i, unknowns)
        })
      end

    end

    alias_method :phrase, :form
    alias_method :token_sets, :tokens

    # (size1 - size2).abs <= distance <= [size1, size2].max
    def distance(other)
      token_sets1, token_sets2 = token_sets, other.token_sets
      size1, size2 = token_sets1.size, token_sets2.size

      return size2 if size1 == 0
      return size1 if size2 == 0

      distance, costs = nil, (0..size2).to_a

      0.upto(size1 - 1) { |index1|
        token_set1, cost = token_sets1[index1], index1 + 1

        0.upto(size2 - 1) { |index2|
          penalty = token_set1.distance(token_sets2[index2])

          # rcov hack :-(
          _ = [
            costs[index2 + 1] + 1,   # insertion
            cost + 1,                # deletion
            costs[index2] + penalty  # substitution
          ]
          distance = _.min

          costs[index2], cost = cost, distance
        }

        costs[size2] = distance
      }

      distance + 1  # > 0 !?!
    end

    def forms
      @forms ||= map { |token_set| token_set.forms }
    end

    def incl(wcs)
      self.class.new(form, map { |token_set| token_set.incl(wcs) })
    end

    def excl(wcs)
      self.class.new(form, map { |token_set| token_set.excl(wcs) })
    end

    def soundex
      ensure_soundex!
      @soundex ||= self.class.new(form, map { |token_set| token_set.soundex })
    end

  end

end
