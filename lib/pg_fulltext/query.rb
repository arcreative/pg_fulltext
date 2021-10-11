require 'rltk/lexer'

module PgFulltext
  module Query
    class Lexer < RLTK::Lexer
      rule(/!+/)
      rule(/"+/)

      rule(/(!?)[\p{L}!]+/) { |v| [:WORD, v] }
      rule(/"[\p{L}\s!]+"/) { |v| [:PHRASE, v[1..-2]] }
      rule(/!"[\p{L}\s!]+"/) { |v| [:NOT_PHRASE, v[2..-2]] }

      rule(/\s+/)
      rule(/[^\p{L}^\s^"]+/)
    end

    def self.to_tsquery_string(query, prefix: true, operator: '&')
      query = normalize_query(query)

      terms = []
      Lexer.lex(query).each do |token|
        if token.type == :WORD
          terms << format_term(token.value, prefix: prefix)
        elsif %i[PHRASE NOT_PHRASE].include?(token.type)
          phrase_terms = Lexer.lex(token.value).map do |phrase_term|
            phrase_term.value.nil? ? nil : format_term(phrase_term.value, prefix: prefix)
          end.compact
          terms << "#{'!' if token.type == :NOT_PHRASE}(#{phrase_terms.join(' <-> ')})"
        end
      end

      terms.join(" #{operator} ")
    end

    private

    def self.normalize_query(query)
      query
        .gsub(/[.,]/, ' ')        # Replace all periods and commas with spaces (reasonable delimiters)
        .gsub(/[^\s\p{L}"!]/, '') # Remove all non-unicode, whitespace, quotes ("), and bangs (!)
        .gsub(/\s+/, ' ')         # Replace repeat whitespace occurrences with single spaces
        .strip                    # Strip space from beginning and end of line
    end

    def self.format_term(term, prefix: true)
      # Remove any ! that's not at the beginning of the term, as it will break the query
      term.gsub!(/(?<!^)!/, '')

      # Add the prefix if prefix is set
      "#{term}#{':*' if prefix}"
    end

    def self.reject_falsy(terms)
      false_values = [nil, '', '"', '!', ':*', '":*', '!:*']
      terms.reject { |v| false_values.include?(v) }
    end
  end
end
