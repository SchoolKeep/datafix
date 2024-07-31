namespace :db do
  namespace :datafix do

    desc "Run the 'up' on the passed datafix"
    task :up => :environment do
      name = ENV['NAME']
      directory = ENV.fetch('DIRECTORY', nil)
      raise 'NAME required' if name.blank?

      require path_from_name(name, directory)
      klass_from_name(name, directory).migrate('up')
    end

    desc "Run the 'down' operation on the passed datafix"
    task :down => :environment do
      name = ENV['NAME']
      directory = ENV.fetch('DIRECTORY', nil)
      raise 'NAME required' if name.blank?

      require path_from_name(name, directory)
      klass_from_name(name, directory).migrate('down')
    end

    private

    def klass_from_name(name, directory)
      name = name.split(File::SEPARATOR).last.gsub(/^\d+_/, '').gsub(/.rb$/, '').camelize
      klass_name = directory ? "Datafixes::#{directory.camelize}::#{name}" : "Datafixes::#{name}"

      klass_name.constantize
    end

    def path_from_name(name, directory)
      unless name =~ %r(^db/datafixes/)
        name = name.underscore
        pattern = "db/datafixes"
        pattern += "/#{directory.underscore}" if directory
        pattern += "/*_#{name}.rb"

        name = Dir.glob(pattern).first
      end
      Rails.root.join(name)
    end

  end

  desc "Run the 'up' on the passed datafix"
  task :datafix => 'datafix:up'
end
