Gem::Specification.new do |spec|
  spec.name        = 'pg_fulltext'
  spec.version     = '0.2.0'
  spec.summary     = 'PostgreSQL fulltext search'
  spec.description = 'Allows simple searching with a variety of options'
  spec.authors     = ['Adam Robertson']
  spec.email       = 'adam@arcreative.net'

  spec.files = Dir['{lib}/**/*', 'Rakefile', 'README.md']

  spec.homepage    = 'https://github.com/arcreative/pg_fulltext'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/arcreative/pg_fulltext'

  spec.add_dependency 'activerecord', '>= 5.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'rltk', '>= 3.0.1'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'with_model'
end
