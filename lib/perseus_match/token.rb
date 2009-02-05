class PerseusMatch

  class Token < String

    WC_RE = %r{[/|]([^/|]*)\z}

    ANY_WC = '*'.freeze

    attr_reader :form, :wc

    def initialize(form, wc = nil)
      @form = form.sub(WC_RE, '')
      @wc   = wc || $1

      super(@form)
    end

    def match?(wcs)
      wcs = [*wcs].compact
      wcs.include?(wc) || wcs.include?(ANY_WC)
    end

    def unk?
      wc == '?'
    end

    def ==(other)
      other.is_a?(self.class) ? form == other.form : form == other
    end

    def eql?(other)
      self == other && wc == other.wc
    end

    def inspect
      "#{super}/#{wc}"
    end

    alias_method :to_s, :inspect

  end

end
