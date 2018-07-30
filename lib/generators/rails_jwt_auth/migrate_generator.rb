class RailsJwtAuth::MigrateGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __dir__)

  def self.next_migration_number(_dir)
    Time.current.strftime('%Y%m%d%H%M%S')
  end

  def create_initializer_file
    migration_template 'migration.rb', "db/migrate/create_#{RailsJwtAuth.table_name}.rb"
  end

  def migration_version
    "[#{Rails.version.split('.')[0..1].join('.')}]"
  end
end
