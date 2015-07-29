require 'pathname'
require 'fileutils'
require 'json'

module Conv
  #class CSV

  #  class << self

  #    def define(format)
  #      obj = new
  #      obj.define format
  #      obj
  #    end
  #  end

  #  def define(format)
  #    @format = format
  #  end

  #  def head
  #    @format.join ','
  #  end

  #  def to_row(vals)
  #    @format.map do |name|
  #      val = vals[name]
  #      next '' if val.nil?
  #      to_col val
  #    end.join ','
  #  end

  #  # implemented by extends
  #  def to_col
  #  end
  #end

  #class ArticleCSV < CSV

  #  def to_col(val)
  #    lines = val.split "\n"
  #    return lines[0] if lines.length == 1
  #    "\"#{lines.map do |l|
  #      # if it is paragraph
  #      case l
  #      when /(（|\()作者.+(\)|）)/
  #        "<p>#{l}</p>"
  #      when /●/
  #        "<h4>#{l.sub /\A　+/, ''}</h4>"
  #      when /，|。/
  #        "<p>　　#{l.sub /\A　　/, ''}</p>"
  #      else
  #        "<h4>#{l.sub /\A　+/, ''}</h4>"
  #      end
  #    end.join}\""
  #  end
  #end

  #class ArticleRow

  #  attr_accessor :year, :content

  #  def initialize(vals)
  #    @year    = vals[:year].to_i
  #    @content = vals[:content]
  #  end
  #end

  class CSVFile

    attr_accessor :filename, :rows
  end

  class Article

    attr_reader :title, :author, :year, :month, :day, :stamp, :body

    require_relative 'articles/china_times'
    require_relative 'articles/udn'
    require_relative 'articles/idn'
    #SOURCES = [ChinaTimes, Udn, Idn]

    require_relative 'report'

    class << self

      # implemented by extends
      def from
      end

      #def csv_files(head)
      #  ['1900-1959', '1960-1969', '1970-1979', '1980-1989', '1990-2100'].map do |year|
      #    file = CSVFile.new
      #    file.filename = "#{year}.csv"
      #    file.rows = [head]
      #    file
      #  end
      #end

      #def group_by_year(article, filename, format, files)
      #  rows = article.to_csv filename, format
      #  rows.each do |row|
      #    year = row.year
      #    index =
      #      year < 1960 ? 0 :
      #      year >= 2000 ? 4 : (year - 1960) / 10 + 1
      #    files[index].rows.push row.content
      #  end
      #end

      #def csv_format
      #  ArticleCSV.define [
      #    'Start Date', 'End Date', 'Headline', 'Text',
      #    'Media', 'Media Credit', 'Media Caption', 'Media Thumbnail',
      #    'Type', 'Tag']
      #end

      def all_to_csv
        head = [
          'Start Date', 'End Date', 'Headline', 'Text',
          'Media', 'Media Credit', 'Media Caption', 'Media Thumbnail',
          'Type', 'Tag']
        files = ['1900-1959', '1960-1969', '1970-1979', '1980-1989', '1990-2100'].map do |year|
          file = CSVFile.new
          file.filename = "#{year}.csv"
          file.rows = [head]
          file
        end
        if ARGV[0] == 'preprocess'
          Dir["articles/authors/*/*.xml"].each do |fname|
            timeline = TimelineParser.new.preprocess(fname)
            #File.open("#{fname}/preprocessed.yml", 'w') do |f|
            File.open("#{fname}/preprocessed.json", 'w') do |f|
              f.write(JSON.pretty_generate(timeline, indent: '  '))
            end
          end
        end
        #drows = []
        #timeline = Dir["articles/authors/*/*.xml"][0..-1].flat_map do |fname|
        #  next if fname =~ /蕭新煌年表/
        #  occasions = TimelineParser.new.parse fname; drows += occasions
        #  occasions.map { |x|h = x.to_csv; [x.group,head.map { |k| h[k] }]}
        #end
        # 張曉春 in
        # 葉啟政
        # 林俊義
        # 蕭新煌
        # 胡佛
        # 李鴻禧
        # 李亦園
        # 張國龍
        # 李永熾
        # 黃武雄
        # 瞿海源
        # 林山田
        # 楊國樞
        # 文崇一
        # 張忠棟
        # 蔡墩銘
        name = '*'
        dir = "articles/authors/#{name}"
        if ARGV[0] == 'parse'
          Dir["#{dir}/*.xml"].each do |fname|
            timeline = TimelineParser.new.parse fname
            #timeline = timeline.map(&:to_h).map.with_index do |h, i|
            #  {'i'=>i}.merge(h)
            #end
            #File.open("#{dir}/parsed.yml", 'w') do |f|
            #  f.write(timeline.to_yaml)
            #end
          end
        end
        if ARGV[0] == 'cont'
          Dir["#{dir}/*.xml"].each do |fname|
            timeline = TimelineParser.new.parse fname
            savename = "#{dir}/parsed.yml"
            i = File.read("#{dir}/parsed-done").to_i
            if File.exists?(savename)
              prev = YAML.load_file(savename)
              timeline = timeline.map(&:to_h).map.with_index do |h, i|
                {'i'=>i}.merge(h)
              end
              pairs = prev.zip(timeline)
              pair = pairs[0..i].find { |p, t| p != t }
              if pair
                puts 'err'
                puts p
                puts t
              else
                if ARGV[1] == 'cont'
                  FileUtils.mv(savename, "#{dir}/parsed-old.yml")
                end
                File.open(savename, 'w') do |f|
                  f.write(timeline.to_yaml)
                end
                puts 'done'
              end
            end
          end
        elsif ARGV[0] == 'first'
          Dir["#{dir}/*.xml"].each do |fname|
            timeline = TimelineParser.new.parse fname
            timeline = timeline.map(&:to_h).map.with_index do |h, i|
              {'i'=>i}.merge(h)
            end
            File.open("#{dir}/parsed.yml", 'w') do |f|
              f.write(timeline.to_yaml)
            end
          end
        end
        #timeline = Dir["articles/authors/*/*.xml"][0..-1].flat_map do |fname|
        #  next if fname =~ /蕭新煌年表/
        #  TimelineParser.new.parse fname
        #end
        #.partition { |x,y| x }.map { |g| g.map { |x,y| y } }
        #File.open('/tmp/body2', 'w') {|f| f.write bodys.to_yaml }
        #[ChinaTimes, Udn, Idn].each do |src|
        #[ChinaTimes].each do |src|
        #  dir = "articles/authors/*/#{src.from}"
        #  Dir["#{dir}/*.xml"].each do |fname|
        #    art = src.parse fname
        #    art.save_yaml! "#{fname[/.*(?=.xml)/]}.yml"
        #    #row = art.to_row head
        #    #year = art.year
        #    #index =
        #    #  year < 1960 ? 0 :
        #    #  year >= 2000 ? 4 : (year - 1960) / 10 + 1
        #    #files[index].rows.push row
        #  end
        #end
        #files.each do |file|
        #  File.open file.filename, 'w' do |f|
        #    f.puts file.rows.map {|r|r.join ','}.join "\n"
        #  end
        #end
      end
      #def all_to_csv
      #  format = csv_format
      #  files = csv_files format.head
      #  xls_to_csv format, files, &method(:group_by_year)
      #  doc_to_csv format, files, &method(:group_by_year)
      #  files.each do |file|
      #    File.open file.filename, 'w' do |f|
      #      f.puts file.rows.join "\n"
      #    end
      #  end
      #end


      #def xls_to_csv(format, files, &block)
      #  Dir["articles/*/*.xls"].each do |fname|
      #    block.call Report.new, fname, format, files
      #  end
      #end

      #def doc_to_csv(format, files, &block)
      #  SOURCES.each do |src|
      #    dir = "articles/*/#{src.from}"
      #    Dir["#{dir}/*.doc", "#{dir}/*.docx"].each do |fname|
      #      block.call src.new, fname, format, files
      #    end
      #  end
      #end
    end

    def save_yaml!(fname)
      File.open(fname, 'w') { |f| f.write self.to_yaml }
      puts fname
    end

    # interface
    def to_row(head)
      date = "%02s-%02s-%02s 0:00:00" % [@year, @month, @day]
      title = "#{@author} - #{@title}"
      text = "\"#{@body.map do |l|
        case l
        when /(（|\()作者.+(\)|）)/ then "<p>#{l}</p>"
        when /●/                    then "<h4>#{l.sub /\A　+/, ''}</h4>"
        when /，|。/                then "<p>　　#{l.sub /\A　　/, ''}</p>"
        else                             "<h4>#{l.sub /\A　+/, ''}</h4>"
        end
      end.join}\""
      cols = {'Start Date' => date,
              'End Date'   => date,
              'Headline'   => title,
              'Text'       => text,
              'Tag'        => '專欄'}
      head.map { |name| cols[name] }
    end
    # interface
    #def to_csv(fname, format)
    #  #doc_to_txt fname
    #  parse fname
    #  date = "%02s-%02s-%02s 0:00:00" % [@year, @month, @day]
    #  title = "#{@author} - #{@title}"
    #  content = format.to_row('Start Date' => date,
    #                          'End Date'   => date,
    #                          'Headline'   => title,
    #                          'Text'       => "#{@body}",
    #                          'Tag'        => '專欄')
    #  [ArticleRow.new(year: @year, content: content)]
    #end

    #def doc_to_txt(fname)
    #  dir = fname.split('/')[0..-2].join '/'
    #  puts fname
    #  `libreoffice --invisible --convert-to txt:Text "#{fname}" --outdir #{dir}`
    #end

    # implemented by extends
    def parse(fname)
    end
  end
end
Conv::Article.all_to_csv
