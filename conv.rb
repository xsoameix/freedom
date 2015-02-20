require 'pathname'

class CSV

  class << self

    def define(format)
      obj = new
      obj.define format
      obj
    end
  end

  def define(format)
    @format = format
  end

  def head
    @format.join ','
  end

  def to_csv(vals)
    @format.map do |name|
      val = vals[name]
      next '' if val.nil?
      lines = val.split "\n"
      if lines.length == 1
        lines[0]
      else
        "\"#{lines.map do |l|
          # if it is paragraph
          case l
          when /(（|\()作者.+(\)|）)/
            "<p>#{l}</p>"
          when /，|。/
            "<p>　　#{l}</p>"
          else
            "<h4>#{l}</h4>"
          end
        end.join}\""
      end
    end.join ','
  end
end

class Article

  attr_reader :title, :author, :body, :year, :month, :day

  class << self

    # interface
    def from
    end

    def doc_to_csv
      arts = []
      Dir["articles/*/#{from}/*.doc"].each do |fname|
        a = new
        a.parse fname
        arts.push a
      end
      to_csv arts
    end

    def to_csv(arts)
      File.open 'all.csv', 'w' do |f|
        format = CSV.define [
          'Start Date', 'End Date', 'Headline', 'Text',
          'Media', 'Media Credit', 'Media Caption', 'Media Thumbnail',
          'Type', 'Tag']
        f.puts format.head
        arts.each do |a|
          f.puts a.to_csv format
        end
      end
    end
  end

  # interface
  def parse(fname)
  end

  def to_csv(format)
    date = "%02d-%02d-%02d 0:00:00" % [@year, @month, @day]
    format.to_csv('Start Date' => date,
                  'End Date'   => date,
                  'Headline'   => "#{@author} - #{@title}",
                  'Text'       => "#{@body}")
  end
end

class ChinaTimes < Article

  class << self

    def from; '中時' end
  end

  def parse(file)
    #dir = fname.split('/')[0..-2].join '/'
    #`libreoffice --invisible --convert-to txt:Text "#{fname}" --outdir #{dir}`
    text = File.read "#{file[/.+(?=.doc)/]}.txt"
    file =~ /(?<author>[^\/]+)\/#{self.class.from}\/(?<fname>[^\/]+)\.doc\Z/
    author = $~['author']
    text =~ /\A(
      \u{FEFF}(?<title>.+)\n#{author}([^\n]+)?\n+|
      (?<title>.+)\n
    )(?<body>.+)\n
    中國時報(?<y>\d+)年(?<m>\d+)月(?<d>\d+)日\n\Z/mx
    if $~.nil?
      require 'pry-nav'
      binding.pry
    end
    @title = $~['title'].split("\n").join
    @author = author
    @body = $~['body']
    @year = $~['y']
    @month = $~['m']
    @day = $~['d']
  end
end
ChinaTimes.doc_to_csv
