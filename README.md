# pg_fulltext

A pretty reasonable PostgreSQL fulltext implementation with minimal configuration

## Installation

```shell
gem install pg_fulltext
```

or add the following to your `Gemfile`:

```shell
gem 'pg_fulltext'
```

and run `bundle install`

## Rails Configuration

This implementation assumes you have a `tsv` column on your model, and that you're generating a string appropriate for 
the language you're using (we don't specify a default, so it will probably default to `'english'` depending on your 
Postgres implementation):

```ruby
class MyModel
  include PgFulltext::ActiveRecord

  add_search_scope
end
```

You can then use the `search` method (configurable via the first parameter of the `add_search_scope` method):

```ruby
MyModel.search('foo bar "include this phrase" -butnotthis -"and and also not this phrase"')
```

The defaults for this include support for negation, phrases, phrase negation, and prefix searches, but those can be 
configured per the following options:

| Option            | Default  | Description |
| ----------------  | :------- | :----------- |
| `tsvector_column` | `tsv`    | If you have a different column containing your tsvector, specify it here. |
| `search_type`     | `simple` | Your PostgreSQL probably defaults to `'english'`, but the default for this option is `simple` to ensure the most predictable behavior. IMPORTANT: Set this to match the tsvector you've generated. |
| `order`           | `true`   | Whether or not the `order` method should be applied against the generated `rank` for the fulltext query. If you just care about returning matches and not their respective rank, set this to `false`. |
| `prefix`          | `true`   | Default search will match partial words as well as whole words. Set this to `false` if only whole words should be matched. |
| `reorder`         | `false`  | If you already have `order` set on this relation, it will take precedence over the fulltext `rank`. `reorder` will call clear, effectively clearing the existing order and applying `rank`. |
| `ignore_accents`  | `false`  | By default, search queries with accents will be sent through as-is. Setting this to `true` will `unaccent()` the query, which helps match `tsv` columns that have also been unaccented.  Alternatively, you can have your `tsv` column be a combination of both, and this option will be unnecesary. Requires the `unaccent` Postgres extension. |
