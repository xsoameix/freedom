require 'csv'

module Conv
  class Report # implements Article

    class Entry

      attr_accessor :author, :body, :period, :tag
    end

    def to_csv(fname, format)
      #doc_to_txt fname
      reports = parse fname
      reports.map do |r|
        pbegin, pend = r.period.map do |p|
          if p.keys.size == 3
            "%02s-%02s-%02s" % [p[:y], p[:m], p[:d]]
          else
            p[:y]
          end
        end
        lines = r.body.split "\n"
        lines = lines[0].split '，'
        title = "#{r.author} - #{lines[0]}"
        body = r.body.gsub ',', '，'
        format.to_row('Start Date' => pbegin,
                      'End Date'   => pend,
                      'Headline'   => title,
                      'Text'       => body,
                      'Tag'        => r.tag)
      end
    end

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
            {y: p}
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
