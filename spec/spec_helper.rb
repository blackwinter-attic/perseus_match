unless Object.const_defined?(:PerseusMatch)
  $: << File.join(File.dirname(__FILE__), '..', 'lib')
  require 'perseus_match'
end

def inform_on_error(*args)
  begin
    yield
  rescue Spec::Expectations::ExpectationNotMetError => err
    unless args.empty?
      puts
      p *args 
      puts
    end

    raise
  end
end
