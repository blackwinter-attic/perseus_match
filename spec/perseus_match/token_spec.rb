describe PerseusMatch::Token do

  it 'should report strictly equal Tokens as ==' do
    PerseusMatch::Token.new('foo', 'a').should == PerseusMatch::Token.new('foo', 'a')
  end

  it 'should report strictly equal Tokens as eql' do
    PerseusMatch::Token.new('foo', 'a').should be_eql(PerseusMatch::Token.new('foo', 'a'))
  end

  it 'should report slightly equal Tokens as ==' do
    PerseusMatch::Token.new('foo', 'a').should == PerseusMatch::Token.new('foo', 'b')
  end

  it 'should *not* report slightly equal Tokens as eql' do
    PerseusMatch::Token.new('foo', 'a').should_not be_eql(PerseusMatch::Token.new('foo', 'b'))
  end

  it 'should include the word class in inspect' do
    PerseusMatch::Token.new('foo', 'a').inspect.to_s.should =~ /\/a\z/
  end

end
