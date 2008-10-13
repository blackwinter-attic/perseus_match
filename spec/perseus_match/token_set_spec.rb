describe PerseusMatch::TokenSet, ' with lingo' do

  before :each do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
  end

  it 'should tokenize a string' do
    PerseusMatch::TokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::TokenSet)
  end

  it 'should be intersectable' do
    t1 = PerseusMatch::TokenSet.new('abc def ghi')
    t2 = PerseusMatch::TokenSet.new('abc def abc')

    is = t1.intersect(t2)

    is.grep(/abc/).size.should == 2
    is.grep(/def/).size.should == 1
    is.grep(/ghi/).size.should == 0
  end

  it 'should include form in inspect' do
    PerseusMatch::TokenSet.new('foo', []).inspect.to_s.should =~ /<foo>/
  end

end if LINGO_FOUND

describe PerseusMatch::TokenSet, ' without lingo' do

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
      File.symlink(path, link)

      PerseusMatch::TokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::TokenSet)

      File.unlink(link)
    }

    temp.unlink

    # reset lingo base
    LINGO_BASE.replace(lingo_base)
  end

end
