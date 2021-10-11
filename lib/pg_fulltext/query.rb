module PgFulltext
  module Query
    def self.to_tsquery_string(query, prefix: true, operator: '&')

      # Normalize search string to a more parseable equivalent
      query = normalize_query(query)

      # Collect terms
      terms = []

      # Phrase mode
      if query.count('"') > 0 && query.count('"') % 2 == 0
        phrase_terms = []
        negate_phrase = false

        query_parts = query.split(' ')
        query_parts.each do |term|

          # Skip if completely comprised of non-unicode word characters
          next if term.gsub(/[^\s\p{L}]/, '') == ''

          if term.start_with?('!"') && !term.end_with?('"')
            phrase_terms << format_term(term[2..-1], prefix: true)
            negate_phrase = true
          elsif term.start_with?('"') && !term.end_with?('"')
            phrase_terms << format_term(term[1..-1], prefix: true)
          elsif phrase_terms.length > 0
            if term.end_with?('"')
              phrase_terms << format_term(term[0..-2], prefix: prefix)
              terms << "#{'!' if negate_phrase}(#{reject_falsy(phrase_terms, prefix: prefix).join(' <-> ')})"
              phrase_terms = []
              negate_phrase = false
            else
              phrase_terms << format_term(term, prefix: prefix)
            end
          else
            terms << format_term(term, prefix: prefix)
          end
        end
      else
        query.gsub! /["]/, ''
        terms = reject_falsy(query.split(' ').map { |v| format_term(v, prefix: prefix) }, prefix: prefix)
      end

      # Join terms with operator
      terms.join(" #{operator} ")
    end

    private

    def self.normalize_query(query)
      query
        .gsub(/[.,]/, ' ')        # Replace all periods and commas with spaces (reasonable delimiters)
        .gsub(/[^\s\p{L}"!]/, '') # Remove all non-unicode, quote ("), and bangs (!)
        .gsub(/"+/, '"')          # Replace Repeat quotes with single double-quote
        .gsub(/!+/, '!')          # Replace Repeat bangs with single bang
        .gsub(/\s+/, ' ')         # Replace repeat whitespace occurrences with single spaces
        .strip                    # Strip space from beginning and end of line
    end

    def self.format_term(term, prefix: true)
      # Remove any ! that's not at the beginning of the term, as it will break the query
      term.gsub!(/(?<!^)!/, '')

      # Add the prefix if prefix is set
      "#{term}#{':*' if prefix}"
    end

    def self.reject_falsy(terms, prefix: true)
      false_values = [nil, '', '"', '!', ':*', '":*', '!:*']
      terms.reject { |v| false_values.include?(v) }
    end
  end
end
