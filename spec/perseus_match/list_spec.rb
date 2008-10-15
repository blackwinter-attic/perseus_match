describe PerseusMatch::List, '::pair' do

  before :all do
    @phrases = %w[foo bar baz]
    @size = @phrases.size
  end

  it 'should produce full list of pairs with correct size' do
    PerseusMatch::List.pair(@phrases).size.should == @size ** 2
  end

  it 'should produce minimal list of pairs with correct size' do
    PerseusMatch::List.pair(@phrases, {}, :minimal => true).size.should == (@size ** 2 - @size) / 2
  end

end
