require 'pathname'

module Conv
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

    def to_row(vals)
      @format.map do |name|
        val = vals[name]
        next '' if val.nil?
        to_col val
      end.join ','
    end

    # implemented by extends
    def to_col
    end
  end

  class ArticleCSV < CSV

    def to_col(val)
      lines = val.split "\n"
      return lines[0] if lines.length == 1
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
  end

  class Article

    attr_reader :title, :author, :body, :year, :month, :day

    require_relative 'articles/china_times'
    require_relative 'articles/udn'
    require_relative 'articles/idn'
    SOURCES = [ChinaTimes, Udn, Idn]

    require_relative 'report'

    class << self

      # implemented by extends
      def from
      end

      def all_to_csv
        File.open 'all.csv', 'w' do |f|
          format = ArticleCSV.define [
            'Start Date', 'End Date', 'Headline', 'Text',
            'Media', 'Media Credit', 'Media Caption', 'Media Thumbnail',
            'Type', 'Tag']
          f.puts format.head
          f.puts xls_to_csv format
          f.puts doc_to_csv format
        end
      end

      def xls_to_csv(format)
        arts = []
        Dir[ "articles/*/*.xls"].each do |fname|
          dir = fname.split('/')[0..-2].join '/'
          r = Report.new
          arts.push r.to_csv fname, format
        end
        arts.join "\n"
      end

      def doc_to_csv(format)
        arts = []
        SOURCES.each do |src|
          dir = "articles/*/#{src.from}"
          Dir["#{dir}/*.doc", "#{dir}/*.docx"].each do |fname|
            a = src.new
            arts.push a.to_csv fname, format
          end
        end
        arts.join "\n"
      end
    end

    # interface
    def to_csv(fname, format)
      #doc_to_txt fname
      parse fname
      date = "%02s-%02s-%02s 0:00:00" % [@year, @month, @day]
      title = "#{@author} - #{@title}"
      format.to_row('Start Date' => date,
                    'End Date'   => date,
                    'Headline'   => title,
                    'Text'       => "#{@body}",
                    'Tag'        => '專欄')
    end

    def doc_to_txt(fname)
      dir = fname.split('/')[0..-2].join '/'
      puts fname
      `libreoffice --invisible --convert-to txt:Text "#{fname}" --outdir #{dir}`
    end

    # implemented by extends
    def parse(fname)
    end
  end
end
Conv::Article.all_to_csv
