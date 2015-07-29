require 'date'
#require 'csv'

module Conv
  class TimelineParser

    class Row

      attr_reader :index, :cols

      class << self

        def load(row)
          new(row['index'], row['cols'].map { |c| Col.load(c) })
        end
      end

      def initialize(index, cols)
        @index, @cols = index, cols
      end

      def to_h
        {'index'=>@index, 'cols'=>@cols}
      end

      def to_s
        to_h.to_s
      end

      def inspect
        to_h.to_s
      end
    end

    class Col

      attr_reader :index, :type, :value

      class << self

        def load(col)
          new(col['index'], col['type'], col['value'])
        end
      end

      def initialize(index, type, value)
        @index, @type, @value = index, type, value
      end

      def to_h
        {'index'=>@index, 'type'=>@type, 'value'=>@value}
      end

      def to_s
        "[#{@index}](#{@type}): #{@value}"
      end

      def inspect
        to_s
      end
    end

    class InvalidError < RuntimeError

      def initialize(fname, row, col)
        @fname, @row, @col = fname, row, col
      end

      def to_s
        "\n#{File.basename(@fname)[/.*(?=\..*)/]}, [#{@row.index}]#{@col}"
      end
    end

    def preprocess(fname)
      strings, sheet = ['strings', 'sheet1']
      .map { |f| Nokogiri::XML.parse File.read "#{fname}/#{f}.xml" }
      si = strings / '/xmlns:sst/xmlns:si'
      sr = sheet / '/xmlns:worksheet/xmlns:sheetData/xmlns:row[position()>1]'
      empty = /\A[\s\n]*\Z/m
      occasions = sr.map do |row|
        cols = row.children.map do |col|
          ci, ct, cv = col.attr('r')[0], col.attr('t'), col.text
          if cv && cv =~ empty
            nil
          elsif ci == 'A'
            if cv && cv =~ /\A\d{5}\Z/ && cv.to_i > 12000 && cv.to_i < 42000
              Col.new(ci, 'int', cv.to_i)
            elsif ct == 's'
              sv = (se = si[cv.to_i]).text
              Col.new(ci, 'str', sv)
            else
              Col.new(ci, 'str', cv)
            end
          elsif ci == 'B'
            if cv && cv =~ /\A\d{5}\Z/ && cv.to_i > 12000 && cv.to_i < 42000
              Col.new(ci, 'int', cv.to_i)
            elsif ct == 's'
              sv = (se = si[cv.to_i]).text
              rv = (re = se / './xmlns:r').map(&:text)
              if rv.size > 1
                lv = re.slice_after do |s|
                  s.at('./xmlns:t').attr('xml:space')=='preserve'
                end.map { |s| s.map(&:text).join }
                Col.new(ci, 'ary', [rv, lv])
              else
                Col.new(ci, 'str', sv)
              end
            else
              Col.new(ci, 'str', cv)
            end
          elsif ci == 'C'
            if ct == 's'
              sv = (se = si[cv.to_i]).text
              Col.new(ci, 'str', sv)
            else
              Col.new(ci, 'str', cv)
            end
          else
            if ct == 's'
              sv = (se = si[cv.to_i]).text
              Col.new(ci, 'str', sv)
            else
              Col.new(ci, 'str', cv)
            end
            #puts "[#{ct}] #{col.attr('t')} #{File.basename(fname)[/.*(?=\..*)/]} #{col.attr('r')}"
          end
        end.compact.map(&:to_h)
        Row.new(row.attr('r'), cols).to_h
      end
    end

    def parse(fname)
      rows = JSON.parse File.read "#{fname}/preprocessed.json"
      empty = /\A[\s\n]*\Z/m
      occasions = rows.map { |r| Row.load(r) }.map do |row|
        title, author, period, stamp, list, body = nil
        row.cols.each do |col|
          ci, ct, cv = col.index, col.type, col.value
          if ci == 'A'
            if ct == 'int'
              period = parse_ctime cv
            elsif ct == 'str'
              if cv =~ /\A？|\?|大二上學期\Z/
                nil
              else
                pp = parse_cperiod cv # pp: processed period
                if pp
                  period = pp
                else
                  raise InvalidError.new fname, row, col
                end
              end
            else
              raise "col A should be parsed: #{col}"
            end
          elsif ci == 'B'
            if ct == 'int'
              period = parse_ctime cv
            elsif ct == 'ary'
              list, body = parse_cevent *cv
            elsif ct == 'str'
              list = cv.split /\s{4}\s*|\n+/
            else
              raise "col B should be parsed: #{col}"
            end
          elsif ci == 'C'
            if ct == 'str'
              if !cv
                raise InvalidError.new fname, row, col
              end
              title,author,period,stamp,body = parse_creport cv
            else
              raise "col C should be parsed: #{col}"
            end
          else
            nil
          end
        end
        if row.cols.find { |c| c.index == 'B' }
          Occasion.new title,author,period,stamp,list,body,Occasion::Event
        elsif row.cols.find { |c| c.index == 'C' }
          Occasion.new title,author,period,stamp,list,body,Occasion::Report
        else
          nil
        end
      end.compact#.select &:title
    end

    #def parse_file(fname)
    #  strings, sheet = ['strings', 'sheet1']
    #  .map { |f| Nokogiri::XML.parse File.read "#{fname}/#{f}.xml" }
    #  si = strings / '/xmlns:sst/xmlns:si'
    #  sr = sheet / '/xmlns:worksheet/xmlns:sheetData/xmlns:row[position()>1]'
    #  empty = /\A[\s\n]*\Z/m
    #  occasions = sr.map do |row|
    #    title, author, period, stamp, list, body, type = nil
    #    row.children.each do |col|
    #      ct, cr = col.text, col.attr('r')[0]
    #      if cr == 'A' then period = parse_cperiod ct, period
    #      elsif col.attr('t') == 's'
    #        st = (se = si[ct.to_i]).text
    #        if type = cr == 'C'
    #          title,author,period,stamp,body = parse_creport(st, period)
    #        elsif cr == 'B'
    #          rt = (re = se / './xmlns:r').map(&:text).reject {|t|t =~ empty}
    #          if rt.size > 1 then list, body = parse_cevent st, re, rt
    #          else                list = st.split /\s{4}\s*|\n+/
    #          end
    #        end # cr == 'D'
    #      elsif ct =~ /^\d+$/ then period = parse_ctime ct
    #      end # ct.empty? == true
    #    end
    #    type = type ? Occasion::Event : Occasion::Report
    #    Occasion.new title, author, period, stamp, list, body, type
    #  end#.select &:title
    #end

    def valid_date?(src, dst = nil)
      if dst.nil? 
        size = src.size
        y, m, d = src
        size > 0 && (y > 1900 && y < 2050 || y >= 0 && y < 100) &&
          (size > 1 ? m > 0 && m < 13 : true) &&
          (size > 2 ? Date.valid_date?(y, m, d) : true) && size < 4
      elsif valid_date? src
        sy, sm, sd = parse_date src
        y, m, d = dst
        c11 = sy < 2000 && y < 100 && sy < y + 1900 ? [y+1900] : [y]
        c32 = y > 1900 ? [y,m] : [sy,y,m]
        x = [[c11],[[sy,y],[y,m]],[[sy,sm,y],c32,[y,m,d]]]
        args = x[src.size-1][dst.size-1]
        !args.nil? && valid_date?(args)
      else
        false
      end
    end

    def parse_date(date)
      ret = []
      y, m, d = date
      if y
        ret << (y >= 0 && y < 100 ? y + 1900 : y)
        if m
          ret << m
          if d
            ret << d
          end
        end
      end
      ret
    end

    def valid_period?(period)
      src, dst = period
      case period.size
      when 1 then valid_date? src
      when 2 then valid_date? src, dst
      else        false
      end
    end

    def parse_period(period)
      case period.size
      when 1 then [parse_date(period[0])]
      when 2
        src, dst = period
        sy, sm, sd = rsrc = parse_date(src)
        y, m, d = dst
        c11 = sy < 2000 && y < 100 && sy < y + 1900 ? [y+1900] : [y]
        c32 = y > 1900 ? [y,m] : [sy,y,m]
        x = [[c11],[[sy,y],[y,m]],[[sy,sm,y],c32,[y,m,d]]]
        [rsrc, parse_date(x[src.size-1][dst.size-1])]
      end
    end

    def parse_body(body)
      n = '一|二|三|四|五|六|七|八|九|十|\d{1,2}'
      q = "(\\(|（)(#{n})(\\)|）)"
      ni = "#{q}、?" # inline list
      li = /(#{n})(、|，|日：|\.)|#{q}|●|──|－－/
      body.slice_when { |x,y| !(x[0..4] =~ li && y[0..4] =~ li) }
      .map do |x|
        x[0][0..4] =~ li ?
          (x.size > 1 ? {'li'=>x}:
           x[0].size < 40 ? {'h1'=>x[0]} : {'p'=>x[0]}):{'p'=>x[0]}
      end
      .flat_map do |l|
        if l['p'] && (m = l['p'].match(ni))
          head, post = m.pre_match, m.post_match
          ls = [m.to_s]
          while m = post.match(ni)
            pre, post = m.pre_match, m.post_match
            ls += [pre, m.to_s]
          end
          ls << post
          [{'p'=>head}] + ls.each_slice(2).map { |h,x| {'li'=>"#{h}#{x}"} }
        else
          [l]
        end
      end
    end

    def parse_list(list)
      list.map { |x| {'li'=>x} }
    end

    def parse_cperiod(ct)
      period = nil
      p = ct.split(/-|－|至|\./).map { |p| p.scan(/\d+/).map &:to_i }
      period = parse_period p if valid_period? p
      if period.nil?
        #err '日期', i.text, fname
      end
      period
    end

    def parse_ctime(ct)
      time = Time.at((ct.to_i - 25569) * 86400).utc
      [[time.year, time.month, time.day]]
    end

    def parse_cevent(rt, lt) # pt: paragraphs of text, lt: list of text
      list, body = nil
      l, r = 0, 0
      st = (rt + lt).join
      pt = rt.slice_after { |p| p[-1] == '。' }.map &:join
      lt = lt.slice_after do |p|
        l += p.scan(/\(|（/).size; r += p.scan(/\)|）/).size
        l = r = 0 if l == r; l == r
      end.map(&:join).slice_when do |x,y|
        !(x =~ /(\/|／|,|:|;)\s*\Z/) || (y =~ /\/|／/)
      end.map(&:join).map(&:strip).flat_map { |x| x.split "\n" }
      para = st =~ /。/ && !(st =~ /\s{10}/)
      if para          then body = parse_body pt
      elsif !lt.empty? then list = parse_list lt
      else                  body = parse_body [rt.join]
      end
      #if !para && !lt.empty?
      #  lt.select { |x| x =~ /(\(|（).*(\/|／).*(\(|（)/||x =~ /(\/|／)\s*\Z/ }
      #  .each { |x| err '項目', x, fname }
      #end
      [list, body]
    end

    def parse_creport(st)
      title, author, period, stamp, body = nil
      empty = /\A[\s\n]*\Z/m
      te = -1
      tt = nil
      ps = st.split(/\n\s*\n/).flat_map.with_index do |x,i| # fetch title
        pt = x.split /\s{4}\s*|\n+/
        if (i == 0 && pt.size >= 1 &&
            pt.all? { |s| s.size < 50 && !(s =~ /【|】|●/) })
          title = pt.map(&:strip).reject { |x| x =~ empty }
          []
        else
          pt
        end
      end.flat_map.with_index do |x,i|
        tp = /(【|\()?(?<y>\d{4}).(?<m>\d{2}).(?<d>\d{2})/ =~ x
        if tp || (tp = /(?<y>\d{4})(?<m>\d{2})(?<d>\d{2})\s/ =~ x)
          te = i
          src = [y,m,d].map &:to_i
          period = [parse_date(src)] if valid_date? src
          stamp = x[tp..-1]
          [x[0...tp], stamp]
        elsif tp = /(?<the_author>【[^】]+】)/ =~ x
          tt = i
          author = the_author
          [x[0...tp], x[tp+author.size..-1]]
        else
          [x]
        end
      end[0..te].map(&:strip).reject { |x| x =~ empty }
      if title.nil?
        if ps.size >= 3 && ps[0..2].all? { |x| x.size < 31 } &&
          !ps[1..2].any? { |x| x =~ /【|】|●/ }
          title, body = ps[0..2], parse_body(ps[3..-1])
        elsif ps.size >= 2 && ps[0..1].all? { |x| x.size < 31 } &&
          !(ps[1] =~ /【|】|●/)
          title, body = ps[0..1], parse_body(ps[2..-1])
        elsif ps.size >= 1 && ps[0].size < 31
          title, body = ps[0..0], parse_body(ps[1..-1])
        elsif tt && ps[0] && ps[0].size < 60
          title, body = ps[0].split(' '), parse_body(ps[1..-1])
        else
          body = parse_body ps
        end
      else
        body = parse_body ps
      end
      [title, author, period, stamp, body]
    end

    def err(name, val, fname)
      puts "#{name}:[#{val}] 檔案:#{File.basename(fname)[/.*(?=\..*)/]}"
    end
  end

  class Occasion # implements Article

    Event, Report = '重大事件', '報導'

    class Entry

      attr_accessor :author, :body, :period, :tag
    end

    attr_reader :title, :author, :period, :stamp, :list, :body, :type

    def initialize(title, author, period, stamp, list, body, type)
      @title, @author, @period, @stamp, @list, @body, @type =
        title, author, period, stamp, list, body, type
    end

    def to_h
      the_period = period ?
        period.map { |d| Date.new(*d).strftime('%Y-%m-%d') } : []
      {'provider_stamp' => @author,
       'origin_stamp' => @stamp,
       'begin_date' => the_period[0],
       'end_date' => the_period[1],
       'title' => @title,
       'list' => @list, 'body' => @body, 'type' => @type}
      .select { |k,v| v }
    end

    def group
      year = @period[0][0]
      (year < 1960 ? 0 :
       year >= 2000 ? 4 : (year - 1960) / 10 + 1)
    end

    def tag(tag, str, style = {})
      #if tag == 'li'
      #  style = {'padding'=>'0 0 .5em 2em',
      #           'text-indent'=>'-2em',
      #           'line-height'=>'1.5em'}
      #elsif tag == 'p'
      #  style = {'text-indent'=>'2em',
      #           'line-height'=>'1.5em',
      #           'color'=>'black'}
      #end
      #style = " style=\"#{style.map { |k,v| "#{k}:#{v};" }.join}\"" : nil
      #"<#{tag}#{style}>#{str}</#{tag}>"
    end

    def to_md # to markdown
    end

    def to_csv(head)
      period = (0..1).map {|p| (0..2).map {|x| (e = @period[p]) ? e[x] : nil}}
      title = @title ? @title[0] : nil
      subtitle = (title ? @title[1..-1] : []).map { |x| tag 'h4', x }
      body = nil
      if @type == Event
        body = (subtitle + (@list ? [tag('ul',@list.map {|x|tag 'li', x}.join)]:
                            @body.map { |x| tag 'p', x })).join
      else
        body = (subtitle + @body.map do |x|
          if    v = x['p']  then tag 'p', v
          elsif v = x['li'] then tag 'ul', v.map { |y| tag 'li', y }.join
          elsif v = x['h1'] then tag 'h4', v end
        end + (@stamp ? [tag('h6', @stamp, 'text-align'=>'right')] : [])).join
      end
      {'Year'       => period[0][0],
       'Month'      => period[0][1],
       'Day'        => period[0][2],
       'End Year'   => period[1][0],
       'End Month'  => period[1][1],
       'End Day'    => period[1][2],
       'Headline'   => title,
       'Text'       => body,
       'Tag'        => @type}
    end

    #def to_csv(fname, format)
    #  #doc_to_txt fname
    #  reports = parse fname
    #  reports.map do |r|
    #    pbegin, pend = r.period.map do |p|
    #      if p.keys.size == 3
    #        "%02s-%02s-%02s" % [p[:y], p[:m], p[:d]]
    #      else
    #        p[:y]
    #      end
    #    end
    #    lines = r.body.split "\n"
    #    if lines[0].nil?
    #      return []
    #    end
    #    lines = lines[0].split '，'
    #    title = "#{r.author} - #{lines[0]}"
    #    body = r.body.gsub ',', '，'
    #    content = format.to_row('Start Date' => pbegin,
    #                            'End Date'   => pend,
    #                            'Headline'   => title,
    #                            'Text'       => body,
    #                            'Tag'        => r.tag)
    #    year = r.period[0][:y]
    #    ArticleRow.new year: year, content: content
    #  end
    #end

    def doc_to_txt(fname)
      puts fname
      `unoconv -f csv -e FilterOptions=35,123,76 "#{fname}"`
    end

    def parse(file)
      puts file
      file =~ /(?<no_ext>.+)\.xls\Z/
      lines = ::CSV.read "#{$~['no_ext']}.csv", col_sep: '#', quote_char: '{'
      lines = lines[1..-1]
      head = ['日期', '重大事件', '報導', '專欄']
      h = head.size.times.map { |i| [head[i], i] }.to_h
      m = file.match /(?<author>[^\/]+)\/[^\/]+\.xls\Z/x
      author = m['author']
      empty = /\A[\s\n]+\Z/m
      index = lines.find { |l| l[h['報導']] =~ /傳統觀念對消費者不利/ }
      lines.select do |l|
        ev = l[h['重大事件']]
        re = l[h['報導']]
        !l[h['日期']].nil? &&
          (!ev.nil? && (ev =~ empty).nil? ||
           !re.nil? && (re =~ empty).nil?)
      end.map do |l|
        period = l[h['日期']].split '-'
        pfirst = period[0].split '/'
        entry = Entry.new
        entry.period = period.map do |p|
          parts = p.split '/'
          if pfirst.size == 3 && parts.size == 1
            y, m, d = parse_date pfirst
            {y: y, m: m, d: parts[0]}
          elsif parts.size == 1
            {y: p[/\d{4}/]}
          else
            y, m, d = parse_date parts
            {y: y, m: m, d: d}
          end
        end
        entry.author = author
        entry.body, entry.tag = l[h['重大事件']].nil? ?
          [l[h['報導']], '報導'] : [l[h['重大事件']], '重大事件']
        entry
      end
    end

    def parse_date(date)
      date[0].size == 4 ? date : date.reverse
    end
  end
end
