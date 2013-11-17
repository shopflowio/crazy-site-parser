class Export
  require 'fileutils'
#-- Summary

#  This is a class that handles exporting to different formats. I still need to
#  put some more thought into the kind of logic I would like this to handle.
#  Should it know about Active::Record.base models? I dunno. How are we going
#  to coordinate all these classes? I dunno. There will need to be quite a bit
#  of logic to accurately dump content into a comfy mexican sofa database. We'll
#  need to create a CmsPage, then a CmsBlock and link them appropriately. That
#  could be very difficult to do agnostically, with methods having no knowledge
#  that they're working with Comfy Mexican Sofa.

#  In the end, there will need to be some kind of macro meant for Comfy Mexican
#  Sofa. And that's totally okay - but ideally that would be a configuration
#  that's fairly simple to write, and the app's methods would still have no
#  knowledge what CMS they are working with.

#  If a simple configuration can be written and shared for Comfy, and another
#  simple configuration can be written and shared for Wordpress, and then
#  if hooking up a new CMS is just a matter of writing a new configuration,
#  I'll consider this lofty goal a success.

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
