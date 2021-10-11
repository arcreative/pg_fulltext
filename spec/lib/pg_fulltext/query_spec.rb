require 'spec_helper'

describe PgFulltext::Query do
  describe '#to_tsquery_string' do
    describe 'prefix option' do
      it 'returns single term with prefix syntax by default' do
        expect(described_class.to_tsquery_string('foo')).to eq('foo:*')
      end

      it 'returns multiple terms with prefix syntax by default' do
        expect(described_class.to_tsquery_string('foo bar')).to eq('foo:* & bar:*')
      end

      it 'returns single term with prefix syntax' do
        expect(described_class.to_tsquery_string('foo', prefix: true)).to eq('foo:*')
      end

      it 'returns multiple terms with prefix syntax' do
        expect(described_class.to_tsquery_string('foo bar', prefix: true)).to eq('foo:* & bar:*')
      end
    end

    describe 'operator option' do
      it 'returns multiple terms with & operator by default' do
        expect(described_class.to_tsquery_string('foo bar', prefix: true)).to eq('foo:* & bar:*')
        expect(described_class.to_tsquery_string('foo bar', prefix: false)).to eq('foo & bar')
      end

      it 'returns multiple terms with specified operator' do
        expect(described_class.to_tsquery_string('foo bar', prefix: true, operator: '|')).to eq('foo:* | bar:*')
        expect(described_class.to_tsquery_string('foo bar', prefix: false, operator: '|')).to eq('foo | bar')
      end

      it 'returns multiple terms with specified operator' do
        expect(described_class.to_tsquery_string('foo bar', prefix: true, operator: '|')).to eq('foo:* | bar:*')
        expect(described_class.to_tsquery_string('foo bar', prefix: false, operator: '|')).to eq('foo | bar')
      end
    end

    describe 'negation' do
      it 'handles single term negation' do
        expect(described_class.to_tsquery_string('!foo')).to eq('!foo:*')
      end

      it 'handles multiple term negation' do
        expect(described_class.to_tsquery_string('!foo !bar baz')).to eq('!foo:* & !bar:* & baz:*')
      end
    end

    describe 'phrases' do
      it 'handles phrase syntax with single term' do
        expect(described_class.to_tsquery_string('foo "bar"')).to eq('foo:* & bar:*')
      end

      it 'handles phrase syntax with two terms' do
        expect(described_class.to_tsquery_string('foo "bar baz"')).to eq('foo:* & (bar:* <-> baz:*)')
      end

      it 'handles phrase syntax with three or more terms' do
        expect(described_class.to_tsquery_string('foo "bar baz ping"')).to eq('foo:* & (bar:* <-> baz:* <-> ping:*)')
      end

      it 'handles two phrases with three or more terms' do
        expect(described_class.to_tsquery_string('"foo bar baz" "fizz buzz"')).to eq('(foo:* <-> bar:* <-> baz:*) & (fizz:* <-> buzz:*)')
      end

      it 'handles phrases with negation' do
        expect(described_class.to_tsquery_string('"foo bar baz" !"fizz buzz"')).to eq('(foo:* <-> bar:* <-> baz:*) & !(fizz:* <-> buzz:*)')
      end

      it 'handles phrases with nested negated terms' do
        expect(described_class.to_tsquery_string('"foo bar baz" !"fizz !buzz"')).to eq('(foo:* <-> bar:* <-> baz:*) & !(fizz:* <-> !buzz:*)')
      end

      it 'omits entirely unusable terms' do
        expect(described_class.to_tsquery_string('!!! &^* foo !"bar !! !baz"')).to eq('foo:* & !(bar:* <-> !baz:*)')
      end
    end
  end

  describe '#normalize_query' do
    it 'does not change a properly-formatted string' do
      query = 'foo bar !baz "fizz !buzz" !"more words" !"even !more !words"'
      expect(described_class.normalize_query(query)).to eq(query)
    end

    it 'does not change international characters' do
      query = 'Hola Cómo estás 你好 世界'
      expect(described_class.normalize_query(query)).to eq(query)
    end

    it 'does not remove double quotes or bangs' do
      query = '!"'
      expect(described_class.normalize_query(query)).to eq('!"')
    end

    it 'removes other characters and punctuation' do
      query = '@#$%^&*()-=_+[]{}\|;:\'/?.,<>`~'
      expect(described_class.normalize_query(query)).to eq('')
    end

    it 'trims spaces from beginning and end of string, and repeat whitespaces within' do
      query = "     one\t\n     two        "
      expect(described_class.normalize_query(query)).to eq('one two')
    end

    it 'trims other whitespace from beginning and end of string, and repeat whitespaces within' do
      query = "\t\t\n\none\t\n     two\n\n\t\t\n"
      expect(described_class.normalize_query(query)).to eq('one two')
    end

    it 'replaces repeat occurrences of double quotes with single quotes' do
      query = 'foo """"""bar baz""'
      expect(described_class.normalize_query(query)).to eq('foo "bar baz"')
    end
  end

  describe '#format_term' do
    it 'does not change a properly-formatted string' do
      query = 'foo'
      expect(described_class.format_term(query, prefix: false)).to eq(query)
    end

    it 'does not change a properly-formatted string with negation' do
      query = '!foo'
      expect(described_class.format_term(query, prefix: false)).to eq(query)
    end

    it 'strips bangs that aren\'t at beginning of string' do
      expect(described_class.format_term('fo!o', prefix: false)).to eq('foo')
    end

    it 'strips additional bangs that aren\'t at beginning of string' do
      expect(described_class.format_term('!fo!o', prefix: false)).to eq('!foo')
    end
  end

  describe '#reject_falsy' do
    it 'does not reject string matching one of the falsy values' do
      good_strings = %w[foo bar !baz foo:* bar:* !baz:*]
      expect(described_class.reject_falsy(good_strings)).to eq(good_strings)
    end

    it 'rejects any string matching one of the expected values' do
      expect(described_class.reject_falsy([nil])).to eq([])
      expect(described_class.reject_falsy([''])).to eq([])
      expect(described_class.reject_falsy(['"'])).to eq([])
      expect(described_class.reject_falsy([':*'])).to eq([])
      expect(described_class.reject_falsy(['":*'])).to eq([])
      expect(described_class.reject_falsy(['!:*'])).to eq([])
    end
  end
end
