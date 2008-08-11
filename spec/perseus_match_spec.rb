require 'rubygems'
require 'nuggets/util/i18n'

describe PerseusMatch do

  before :all do
    @highly_similar = [
      'Anbetung der Könige',
      'Die Anbetung der Könige'
    ]  # ok

    @similar = [
      # @highly_similar + ...
      'Die Anbetung der Heiligen Drei Könige',
      'dIE AnBeTuNg der heILIGen dREI KÖniGE'
    ]  # ok

    @unfortunately_similar = [
      # @similar + ...
      'Die Die Die Anbetung der Könige',
      'Die Könige der Anbetung',
      'Königsanbetung hoch drei'
    ]  # *not* ok -- eventually try to drop these

    @somewhat_similar = @highly_similar + @similar + @unfortunately_similar

    @matchings = PerseusMatch.match(@somewhat_similar + [
      'Drei mal drei macht sechs',
      'Das Ende dieses Blödsinns',
      ''
    ])
  end

  it 'should identify identical (non-empty) strings as identical' do
    @matchings.each { |matching|
      if !matching.phrase.empty? && matching.phrase == matching.target
        inform_on_error(matching) { matching.similarity.should == 1.0 }
      end
    }
  end

  it 'should identify case-insensitively identical (non-empty) strings as identical' do
    @matchings.each { |matching|
      if !matching.phrase.empty? && matching.phrase.replace_diacritics.downcase == matching.target.replace_diacritics.downcase
        inform_on_error(matching) { matching.similarity.should == 1.0 }
      end
    }
  end

  it 'should identify *only* case-insensitively identical (non-empty) strings as identical' do
    @matchings.each { |matching|
      if !matching.phrase.empty? && matching.phrase.replace_diacritics.downcase != matching.target.replace_diacritics.downcase
        inform_on_error(matching) { matching.similarity.should < 1.0 }
      end
    }
  end

  it 'should identify disjunct (non-empty) strings as disjunct' do
    @matchings.each { |matching|
      if !matching.phrase.empty? && matching.phrase_tokens.disjoint?(matching.target_tokens)
        inform_on_error(matching) { matching.similarity.should == 0.0 }
      end
    }
  end

  it 'should identify empty string as disjunct with anything, even with itself' do
    @matchings.each { |matching|
      if matching.phrase.empty? || matching.target.empty?
        inform_on_error(matching) { matching.similarity.should == 0.0 }
      end
    }
  end

  it 'should identify certain strings as highly similar' do
    @matchings.each { |matching|
      if @highly_similar.include?(matching.phrase) && @highly_similar.include?(matching.target)
        inform_on_error(matching) { matching.similarity.should > 0.9 }
      end
    }
  end

  it 'should identify certain strings as similar' do
    @matchings.each { |matching|
      if @similar.include?(matching.phrase) && @similar.include?(matching.target)
        inform_on_error(matching) { matching.similarity.should > 0.8 }
      end
    }
  end

  it 'should *not* identify other strings as similar' do
    @matchings.each { |matching|
      if @somewhat_similar.include?(matching.phrase) && !@somewhat_similar.include?(matching.target)
        inform_on_error(matching) { matching.similarity.should_not > 0.8 }
      end
    }
  end

  it 'should be symmetrical' do
    similarities = {}

    @matchings.each { |matching|
      if similarity = similarities[[matching.target, matching.phrase]]
        inform_on_error(matching) { similarity.should == matching.similarity }
      else
        similarities[[matching.phrase, matching.target]] = matching.similarity
      end
    }
  end

end
