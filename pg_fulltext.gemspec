Gem::Specification.new do |s|
  s.name        = 'pg_fulltext'
  s.version     = '0.1.0'
  s.summary     = 'PostgreSQL fulltext search'
  s.description = 'Allows simple searching with a variety of options'
  s.authors     = ['Adam Robertson']
  s.email       = 'adam@arcreative.net'
  s.files       = %w[
    lib/pg_fulltext.rb
    lib/pg_fulltext/model.rb
    lib/pg_fulltext/query.rb
  ]
  s.homepage    =
    'https://github.com/arcreative/pg_fulltext'
  s.license     = 'MIT'
end
