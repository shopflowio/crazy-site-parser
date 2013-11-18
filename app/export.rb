class Export
  require 'fileutils'
#-- Summary

#  This is a class that handles exporting to different formats.

  def self.to_file(data, path)
    FileUtils.mkdir_p File.dirname(path)

    File.open(path, 'w') do |f|
      f.write data
    end
  end

  def self.images(img_paths, src_root, out_root)
    not_found = []
    img_paths.each do |img_path|
      FileUtils.mkdir_p (out_root + File.dirname(img_path))

      begin
	File.open(src_root + img_path, 'r') do |img|
	  File.open(out_root + img_path, 'w') do |f|
	    f.write img
	  end
	end
      rescue Errno::ENOENT
        not_found << img_path
      end
    end
    puts "Could not find: #{not_found * ', '}" unless not_found.empty?
  end
  

end
