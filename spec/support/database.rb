begin
  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'pg_fulltext_test',
    username: ENV['USER'],
    min_messages: 'warning',
    url: ENV['DATABASE_URL'],
  )
  connection = ActiveRecord::Base.connection
  connection.execute('SELECT 1')
rescue PG::Error, ActiveRecord::NoDatabaseError => e
  at_exit do
    puts 'Unable to connect to database `pg_fulltext_test`'
  end
  raise e
end

if ENV['LOG_ACTIVERECORD']
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout)
end

def install_extension(name)
  connection = ActiveRecord::Base.connection
  extension = connection.execute "SELECT * FROM pg_catalog.pg_extension WHERE extname = '#{name}';"
  return unless extension.none?

  connection.execute "CREATE EXTENSION #{name};"
rescue StandardError => e
  at_exit do
    puts "Unable to install the `#{name}` extension, please install it with an account with proper privileges."
  end
  raise e
end

def install_extension_if_missing(name, query, expected_result)
  result = ActiveRecord::Base.connection.select_value(query)
  raise "Unexpected output for #{query}: #{result.inspect}" unless result.casecmp(expected_result).zero?
rescue StandardError
  install_extension(name)
end

install_extension_if_missing('unaccent', 'SELECT unaccent(\'cómo estás\')', 'como estas')
