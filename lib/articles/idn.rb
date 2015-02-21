class Idn < Article

  class << self

    def from; '自立晚報' end
  end

  def parse(file)
    file =~ /(?<no_ext>.+)\.docx?\Z/
    text = File.read "#{$~['no_ext']}.txt"
    m = file.match /(?<author>[^\/]+)\/#{self.class.from}\/
    (?<y>\d{4})(?<m>\d{2})(?<d>\d{2})(?<title>.+)\.docx?\Z/x
    @author = m['author']
    @title = m['title'].sub '自立晚報 ', ''
    @year = m['y']
    @month = m['m']
    @day = m['d']
    text.sub! "\u{FEFF}", ''
    i = text =~ /\n\n/
    if text =~ /\A訂正/
      text =~ /\A[^\n]+[\n\s]+(?<body>.+)\n\Z/mx
    elsif (i.is_a? Fixnum) && i < 100
      text =~ /\A.+?\n\n(?<body>.+)\n
      自立晚報　(?<y>\d+)年(?<m>\d+)月(?<d>\d+)日[\s\n]+\Z/mx
    else
      text =~ /\A[^\n]+\n[^\n]+\n(?<body>.+)\n
      自立晚報　?(?<y>\d+)年(?<m>\d+)月(?<d>\d+)日[\s\n]+\Z/mx
    end
    if $~.nil?
      require 'pry-nav'
      binding.pry
    end
    @body = $~['body']
  end
end
