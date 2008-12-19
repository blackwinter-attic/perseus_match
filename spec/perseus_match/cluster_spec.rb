describe PerseusMatch::Cluster do

  it 'should accept limit option in sort_by' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:similarity, :limit => 1).all? { |phrase, matches|
      matches.size.should == 1
      matches.size.should == matches.nitems
    }
  end

  it 'should accept threshold option in sort_by (1a)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:similarity, :threshold => 0.1).all? { |phrase, matches|
      matches.size.should == 1
      matches.size.should == matches.nitems
      matches.each { |match| match.target.should == phrase }
    }
  end

  it 'should accept threshold option in sort_by (1b)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:similarity, :threshold => 0).all? { |phrase, matches|
      matches.size.should == 2
      matches.size.should == matches.nitems
    }
  end

  it 'should accept threshold option in sort_by (2)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:target, :threshold => 'c').all? { |phrase, matches|
      matches.size.should == 1
      matches.size.should == matches.nitems
    }
  end

  it 'should accept both limit and threshold options in sort_by (1)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:target, :threshold => 'z', :limit => 1).all? { |phrase, matches|
      matches.size.should == 1
      matches.size.should == matches.nitems
    }
  end

  it 'should accept both limit and threshold options in sort_by (2)' do
    PerseusMatch::Cluster.new(%w[foo bar]).sort_by(:target, :threshold => 'a', :limit => 1).all? { |phrase, matches|
      matches.size.should be_zero
      matches.size.should == matches.nitems
    }
  end

end if LINGO_FOUND
