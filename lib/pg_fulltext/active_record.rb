require 'securerandom'

module PgFulltext
  module ActiveRecord
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Class method to add a scope to the class, searching against `tsv` column by default
      def add_search_scope(name = :search, **options)
        self.scope name, -> (query) {
          apply_search_to_relation(self, query, **options)
        }
      end

      def apply_search_to_relation(
        relation,
        query,
        tsvector_column: :tsv,
        search_type: nil,
        order: true,
        prefix: true,
        reorder: false,
        any_word: false,
        ignore_accents: false
      )
        serial = SecureRandom.hex(4)
        pk_quoted = "#{quoted_table_name}.#{connection.quote_column_name(primary_key)}"
        fulltext_join_name = "pg_fulltext_#{serial}"

        # Build the search relation to join on
        search_relation = get_search_relation(
          relation,
          query,
          tsvector_column: tsvector_column,
          search_type: search_type,
          any_word: any_word,
          prefix: prefix,
          ignore_accents: ignore_accents,
        )

        # Join the search relation
        relation = relation.joins("INNER JOIN (#{search_relation.to_sql}) AS #{fulltext_join_name} ON #{fulltext_join_name}.id = #{pk_quoted}")

        # Order/reorder against the search rank
        if order || reorder
          relation = relation.send(reorder ? :reorder : :order, "#{fulltext_join_name}.rank DESC")
        end

        # Return the model relation
        relation
      end

      def get_search_relation(
        relation,
        query,
        tsvector_column: :tsv,
        search_type: nil,
        any_word: false,
        prefix: true,
        ignore_accents: false
      )
        tsquery_string_quoted = connection.quote(PgFulltext::Query.to_tsquery_string(query, operator: any_word ? '|' : '&', prefix: prefix))
        tsquery_string_quoted = "unaccent(#{tsquery_string_quoted})" if ignore_accents
        column_quoted = connection.quote_column_name(tsvector_column)
        fqc_quoted = "#{quoted_table_name}.#{column_quoted}"
        tsquery = "to_tsquery(#{"#{connection.quote search_type}, " if search_type.present?}#{tsquery_string_quoted})"

        relation
          .select(:id, "ts_rank_cd(#{fqc_quoted}, #{tsquery}) AS rank")
          .where("#{fqc_quoted} @@ #{tsquery}")
      end
    end
  end
end
