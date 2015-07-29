require 'fileutils'
require 'zip'

Dir['authors/*/*/*.docx'].sort.each do |f|
  xml = "#{f[/.*(?=\..*)/]}.xml"
  next if File.exist? xml
  Zip::File.open(f) { |zf| zf.extract 'word/document.xml', xml }
  puts xml
end
Dir['authors/*/*.xlsx'].sort.each do |f|
  xml = "#{f[/.*(?=\..*)/]}.xml"
  next if File.exist? xml
  Dir.mkdir xml
  Zip::File.open f do |zf|
    zf.extract 'xl/sharedStrings.xml', "#{xml}/strings.xml"
    zf.map(&:name).select { |x| x =~ /^xl\/worksheets\/sheet\d+\.xml$/ }
    .each { |s| zf.extract s, "#{xml}/#{File.basename s}" }
  end
  puts xml
end
