class PerseusMatch

  class Cluster < Hash

    def initialize(phrases = [])
      super() { |h, k| h[k] = [] }

      List.new(phrases).each { |pm| add(pm) }
    end

    def add(pm)
      self[pm.phrase] << pm
    end

    alias_method :<<, :add

    def sort_by(attribute, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}

      map { |phrase, matches|
        res = {}

        matches = matches.sort_by { |match|
          res[match] = match.send(attribute, *args)
        }

        # premise: if any is, then all are (i.e., only first needs checking)
        numeric = res.any? { |_, r| break r.is_a?(Numeric) }

        # sort numeric results in reverse order
        matches.reverse! if numeric

        if threshold = options[:threshold]
          condition = numeric ?
            lambda { |match| res[match] < threshold } :
            lambda { |match| res[match] > threshold }

          matches.reject! { |match| condition[match] }
        end

        if limit = options[:limit]
          matches.slice!(limit..-1)
        end

        # transform entries if so requested
        matches.map!(&block) if block

        [phrase, matches]
      }.sort
    end

    def sort(options = {}, &block)
      sort_by(:similarity, options.delete(:coeff), options, &block)
    end

    def rank(options = {})
      coeff = options[:coeff]
      sort(options) { |match| [match.target, match.similarity(coeff)] }
    end

  end

end
