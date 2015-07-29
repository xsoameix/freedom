if ARGV.size == 3 && ARGV.all? { |c| c =~ /\A\d+\Z/ }
  puts Time.utc(*ARGV).tv_sec / 86400 + 25569
end
