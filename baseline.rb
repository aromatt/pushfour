#!/usr/bin/env ruby

require 'open3'

script = File.expand_path(__FILE__)
Dir.chdir(File.dirname(script))

opts = ARGV.dup
switches = opts.select { |x| x[0] == '-' }.join.split('')
switches.delete('-')

baseline = switches.delete('b')
verbose = switches.delete('v')
failed = updated = matched = 0

unless switches.empty?
  abort "Unrecognized switch: #{switches.first}"
end

scenarios = opts.reject { |x| x[0] == '-' }
scenarios = Dir.glob('regress/*.rb') if scenarios.empty?
scenarios.each do |s|
  unless File.file?(s) and File.executable?(s)
    abort "Not an executable scenario: #{s}"
  end
end

scenarios.sort.each do |s|
  b = s + ".baseline"
  name = File.absolute_path(s).split('regress/')[1]
  print (name + ':' + ' ' * 50)[0, 50]
  unless baseline or File.file?(b)
    puts '[ BASELINE MISSING ]'
    next
  end

  # Run the test and compare
  s_out, s_err, status = Open3.capture3("ruby #{s}")
  bt = (File.read(b) rescue '')
  matches = (bt.strip == s_out.strip)

  # Show the results
  if baseline
    if matches and File.file?(b)
      puts '[ UP TO DATE ]'
      matched += 1
    elsif s_out.downcase.include?('fatal')
      puts '[ ERROR ]'
      puts s_out
      puts "-- STDERR --"
      puts s_err
      failed += 1
    else
      File.write(b, s_out)
      puts '[ BASELINED ]'
      updated += 1
    end
  else
    if matches
      puts '[ PASSED ]'
      matched += 1
    else
      puts '[ MISMATCH ]'
      failed += 1
      if verbose
        File.write('/tmp/sedition_baseline.tmp', s_out)
        puts `diff #{b} /tmp/sedition_baseline.tmp`

        if !s_err.strip.empty? and verbose
          puts "-- STDERR --"
          puts s_err
        end
      end
    end
  end
end
