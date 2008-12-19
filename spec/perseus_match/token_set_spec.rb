describe PerseusMatch::TokenSet, ' with lingo' do

  before :each do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
  end

  before :all do
    @original_tokens = PerseusMatch::TokenSet.instance_variable_get(:@tokens)
  end

  after :all do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, @original_tokens)
  end

  it 'should tokenize a string' do
    PerseusMatch::TokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::TokenSet)
  end

  it 'should report strictly equal TokenSets as ==' do
    PerseusMatch::TokenSet.new('foo bar').should == PerseusMatch::TokenSet.new('foo bar')
  end

  it 'should report strictly equal TokenSets as eql' do
    PerseusMatch::TokenSet.new('foo bar').should be_eql(PerseusMatch::TokenSet.new('foo bar'))
  end

  it 'should report slightly equal TokenSets as ==' do
    PerseusMatch::TokenSet.new('foo bar').should == PerseusMatch::TokenSet.new('Foo Bar')
  end

  it 'should *not* report slightly equal TokenSets as eql' do
    PerseusMatch::TokenSet.new('foo bar').should_not be_eql(PerseusMatch::TokenSet.new('Foo Bar'))
  end

  it 'should include form in inspect' do
    PerseusMatch::TokenSet.new('foo', []).inspect.to_s.should =~ /<foo>/
  end

end if LINGO_FOUND

describe PerseusMatch::TokenSet, ' without lingo' do

  before :each do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
  end

  before :all do
    @original_tokens = PerseusMatch::TokenSet.instance_variable_get(:@tokens)
  end

  after :all do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, @original_tokens)
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
      File.symlink(path, link)

      PerseusMatch::TokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::TokenSet)

      File.unlink(link)
    }

    temp.unlink

    # reset lingo base
    LINGO_BASE.replace(lingo_base)
  end

end
