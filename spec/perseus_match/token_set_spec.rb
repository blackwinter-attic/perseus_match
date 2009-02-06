describe PerseusMatch::PhraseTokenSet do

  describe 'with lingo' do

    before :all do
      @original_tokens = PerseusMatch::TokenSet.instance_variable_get(:@tokens)
      @original_phrase_tokens = PerseusMatch::PhraseTokenSet.instance_variable_get(:@tokens)
    end

    after :all do
      PerseusMatch::TokenSet.instance_variable_set(:@tokens, @original_tokens)
      PerseusMatch::PhraseTokenSet.instance_variable_set(:@tokens, @original_phrase_tokens)
    end

    before :each do
      PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
      PerseusMatch::PhraseTokenSet.instance_variable_set(:@tokens, nil)
    end

    it 'should tokenize a string' do
      PerseusMatch::PhraseTokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::PhraseTokenSet)
    end

    it 'should report strictly equal PhraseTokenSets as ==' do
      PerseusMatch::PhraseTokenSet.new('foo bar').should == PerseusMatch::PhraseTokenSet.new('foo bar')
    end

    it 'should report strictly equal PhraseTokenSets as eql' do
      PerseusMatch::PhraseTokenSet.new('foo bar').should be_eql(PerseusMatch::PhraseTokenSet.new('foo bar'))
    end

    it 'should report slightly equal PhraseTokenSets as ==' do
      PerseusMatch::PhraseTokenSet.new('foo bar').should == PerseusMatch::PhraseTokenSet.new('Foo Bar')
    end

    it 'should *not* report slightly equal PhraseTokenSets as eql' do
      PerseusMatch::PhraseTokenSet.new('foo bar').should_not be_eql(PerseusMatch::PhraseTokenSet.new('Foo Bar'))
    end

    it 'should collect unknown tokens' do
      unknowns = []
      PerseusMatch::PhraseTokenSet.tokenize('foo bar', unknowns)
      unknowns.should == %w[foo]
    end

    it 'should include form in inspect' do
      PerseusMatch::PhraseTokenSet.new('foo', []).inspect.to_s.should =~ /<foo>/
    end

  end if LINGO_FOUND

  describe 'without lingo' do

    before :all do
      @original_tokens = PerseusMatch::TokenSet.instance_variable_get(:@tokens)
    end

    after :all do
      PerseusMatch::TokenSet.instance_variable_set(:@tokens, @original_tokens)
    end

    before :each do
      PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
    end

    it 'should take a prepared file for tokenization' do
      # prevent lingo from being used
      lingo_base = LINGO_BASE.dup
      LINGO_BASE.replace('')

      temp = Tempfile.open('perseus_match_spec_tokens_temp') { |t|
        t.puts *%w[<foo|?> <bar|?>]
      }

      path = temp.path
      link = 'perseus.tokens'

      Dir.chdir(File.dirname(path)) {
        begin
          File.symlink(path, link)
          PerseusMatch::PhraseTokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::PhraseTokenSet)
        ensure
          File.unlink(link) if File.symlink?(link) && File.readlink(link) == path
        end
      }

      temp.unlink

      # reset lingo base
      LINGO_BASE.replace(lingo_base)
    end

  end

  it 'should raise an error if asked for Soundex but is not available' do
    soundex = Text.send(:remove_const, :Soundex)

    lambda {
      PerseusMatch::PhraseTokenSet.new('foo bar').soundex
    }.should raise_error(RuntimeError, /soundex/i)

    Text::Soundex = soundex
  end

end
