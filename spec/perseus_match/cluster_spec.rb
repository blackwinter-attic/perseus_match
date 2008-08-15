describe PerseusMatch::Cluster do

  it 'should accept options in sort_by (1)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:similarity, :threshold => 0.1, :limit => 1).all? { |phrase, matches|
      matches.length.should == 1
    }
  end

  it 'should accept options in sort_by (2)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:phrase, :threshold => 'a', :limit => 1).all? { |phrase, matches|
      matches.length.should == 1
    }
  end

end
