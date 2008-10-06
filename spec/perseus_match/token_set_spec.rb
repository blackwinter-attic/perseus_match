describe PerseusMatch::TokenSet do

  before :each do
    PerseusMatch::TokenSet.instance_variable_set(:@tokens, nil)
  end

  it 'should tokenize a string' do
    PerseusMatch::TokenSet.tokenize('foo bar').should be_an_instance_of(PerseusMatch::TokenSet)
  end if LINGO_FOUND

  it 'should take a prepared file for tokenization' do
    # prevent lingo from being used
    lingo_base = LINGO_BASE.dup
    LINGO_BASE.replace('')

    temp = Tempfile.new('perseus_match_spec_tokens_temp')
    temp.puts *%w[<foo|?> <bar|?>]
    temp.close

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

  it 'should include form in inspect' do
    PerseusMatch::TokenSet.new('foo', []).inspect.to_s.should =~ /<foo>/
  end

end
