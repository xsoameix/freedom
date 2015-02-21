class Udn < Article

  class << self

    def from; '聯合' end
  end

  def parse(file)
    file =~ /(?<no_ext>.+)\.docx?\Z/
    text = File.read "#{$~['no_ext']}.txt"
    file =~ /(?<author>[^\/]+)\/#{self.class.from}\/
    (?<y>\d{4})(?<m>\d{2})(?<d>\d{2})(?<title>.+)\.docx?\Z/x
    @author = $~['author']
    @title = $~['title']
    @year = $~['y']
    @month = $~['m']
    @day = $~['d']
    text.sub! "\u{FEFF}", ''
    text.sub! /【\d+-\d+-\d+\/.+/m, ''
    i = text =~ /\n\n|【#{@author}】/
    if (i.is_a? Fixnum) && i < 100
      text.sub! /【#{@author}】[\n\s]+/m, ''
      text =~ /\A.+?\n\n?(?<body>.+)\Z/mx
    else
      text =~ /\A[^\n]+\n(?<body>.+)\Z/mx
    end
    @body = $~['body']
  end
end
