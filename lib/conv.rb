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
          when /●/
            "<h4>#{l.sub /\A　+/, ''}</h4>"
          when /，|。/
            "<p>　　#{l.sub /\A　　/, ''}</p>"
          else
            "<h4>#{l.sub /\A　+/, ''}</h4>"
          end
        end.join}\""
      end
    end.join ','
  end
end

class Article

  attr_reader :title, :author, :body, :year, :month, :day

  require_relative 'articles/china_times'
  require_relative 'articles/udn'
  require_relative 'articles/idn'
  SOURCES = [ChinaTimes, Udn, Idn]

  class << self

    # interface
    def from
    end

    def doc_to_csv
      arts = []
      SOURCES.each do |src|
        dir = "articles/*/#{src.from}"
        Dir["#{dir}/*.doc", "#{dir}/*.docx"].each do |fname|
          a = src.new
          #a.doc_to_txt fname
          a.parse fname
          arts.push a
        end
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

  def doc_to_txt(fname)
    dir = fname.split('/')[0..-2].join '/'
    puts fname
    `libreoffice --invisible --convert-to txt:Text "#{fname}" --outdir #{dir}`
  end

  # interface
  def parse(fname)
  end

  def to_csv(format)
    date = "%02s-%02s-%02s 0:00:00" % [@year, @month, @day]
    format.to_csv('Start Date' => date,
                  'End Date'   => date,
                  'Headline'   => "#{@author} - #{@title}",
                  'Text'       => "#{@body}")
  end
end
Article.doc_to_csv
