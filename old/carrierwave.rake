# CarrierWave rake tasks
#
# Task:   reprocess
# Desc:   Reprocess all images for a given class
# Usage:  rake carrierwave:reprocess class=<ClassName> mount_uploader=<mount_uploader>
namespace :carrierwave do
  task :reprocess, [:class, :mount_uploader] => :environment do |task, args|
    desc "Reprocess all images for a given class."

    # Get class hierarchy
    class_chain = args[:class].split('.')

    # Starting class
    start = class_chain.shift

    # run down the tree to find all the children
    instances = class_chain.inject(start.constantize.all) do |objs, child|
      objs.map do |obj|
        print '.'
        obj.send child.to_sym
      end.flatten
    end

    # itterate the children
    instances.each do |object|
      begin
        object.update_attributes({args[:mount_uploader].to_sym => object.instance_eval(args[:mount_uploader])})
        print '.'
      rescue Exception => e
        debugger
        print 'E'
        false
      end
    end
    puts
  end
end
