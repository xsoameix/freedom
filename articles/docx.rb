require 'win32ole'

def chgext f, new
  old = File.extname f
  name = File.basename f, old
  pwd = "#{Dir.pwd}/#{File.dirname f}"
  bas = "#{pwd.gsub "\/", "\\"}\\#{name}"
  ["#{bas}#{old}", "#{bas}#{new}"]
end

word = WIN32OLE.new 'Word.Application'
Dir['authors/*/*/*.doc'].sort.each do |f|
  old, new = chgext f, '.docx'
  next if File.exist? new
  doc = word.Documents.Open old
  doc.SaveAs new, 12
  doc.Close
  puts new
end
word.Quit
excel = WIN32OLE.new 'Excel.Application'
Dir['authors/*/*.xls'].sort.each do |f|
  old, new = chgext f, '.xlsx'
  next if File.exist? new
  xls = excel.WorkBooks.Open old
  xls.SaveAs new, 51
  xls.Close
  puts new
end
excel.Quit
