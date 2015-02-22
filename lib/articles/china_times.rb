module Conv
  class ChinaTimes < Article

    class << self

      def from; '中時' end
    end

    def parse(file)
      file =~ /(?<no_ext>.+)\.docx?\Z/
      text = File.read "#{$~['no_ext']}.txt"
      m = file.match /(?<author>[^\/]+)\/#{self.class.from}\/
      (?<y>\d{4})(?<m>\d{2})(?<d>\d{2})(?<title>.+)\.docx?\Z/x
      @author = m['author']
      @title = m['title'].sub '  中時  ', ''
      @year = m['y']
      @month = m['m']
      @day = m['d']
      text.sub! "\u{FEFF}", ''
      i = text =~ /\n\n/
      if (i.is_a? Fixnum) && i < 100
        text =~ /\A.+?\n\n(?<body>.+)\Z/m
      else
        lines = text.split "\n"
        text = lines[(lines[2] == @author ? 3 : 2)..-1].join "\n"
        text =~ /\A(?<body>.+)\Z/m
      end
      @body = $~['body']
    end
  end
end
