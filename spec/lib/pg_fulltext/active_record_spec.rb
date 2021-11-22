require 'spec_helper'

describe PgFulltext::ActiveRecord do
  with_model :User do
    table do |t|
      t.string :first_name
      t.string :last_name
      t.tsvector :tsv
    end

    model do
      include PgFulltext::ActiveRecord
    end
  end

  describe '#add_search_scope' do
    it 'builds a chainable scope' do
      User.add_search_scope
      scope = User.all.search('foo').all
      expect(scope).to be_an ActiveRecord::Relation
    end

    it 'builds a chainable scope with a custom name' do
      User.add_search_scope :better_search_scope
      scope = User.all.better_search_scope('foo').all
      expect(scope).to be_an ActiveRecord::Relation
    end

    # Options
    let(:scope_name) { :search }
    let(:tsvector_column) { nil }
    let(:search_type) { nil }
    let(:order) { nil }
    let(:reorder) { nil }
    let(:any_word) { nil }
    let(:prefix) { nil }
    let(:ignore_accents) { nil }

    # Various models
    let!(:jim) { User.create(first_name: 'Jim', last_name: 'Jones') }
    let!(:john) { User.create(first_name: 'John', last_name: 'Jones') }
    let!(:billy_bob) { User.create(first_name: 'Billy Bob', last_name: 'Jeffers') }
    let!(:numbers_person) { User.create(first_name: '12345', last_name: '54321') }

    before do
      User.connection.execute <<~SQL.squish
        UPDATE #{User.quoted_table_name}
        SET tsv = to_tsvector('english'::regconfig, first_name || ' ' || last_name)
      SQL

      User.add_search_scope(
        scope_name,
        **{
          tsvector_column: tsvector_column,
          search_type: search_type,
          order: order,
          reorder: reorder,
          any_word: any_word,
          prefix: prefix,
          ignore_accents: ignore_accents,
        }.compact,
      )
    end

    context 'with defaults' do
      it 'simple first name query returns expected users' do
        results = User.search('Jim')
        expect(results).to include(jim)
        expect(results).not_to include(john, billy_bob, numbers_person)
      end

      it 'simple last name query returns expected users' do
        results = User.search('Jones')
        expect(results).to include(jim, john)
        expect(results).not_to include(billy_bob, numbers_person)
      end

      it 'simple number name query returns expected users' do
        results = User.search('12345')
        expect(results).to include(numbers_person)
        expect(results).not_to include(jim, john, billy_bob)
      end

      it 'simple number name query (partial) returns expected users' do
        results = User.search('123')
        expect(results).to include(numbers_person)
        expect(results).not_to include(jim, john, billy_bob)
      end

      it 'negation on last name query returns expected users' do
        results = User.search('!Jones')
        expect(results).to include(billy_bob, numbers_person)
        expect(results).not_to include(jim, john)
      end

      it 'phrase search returns expected users' do
        results = User.search('"Billy Bob"')
        expect(results).to include(billy_bob)
        expect(results).not_to include(jim, john, numbers_person)
      end

      it 'negated phrase search with reversed terms returns no users' do
        results = User.search('!"Billy Bob"')
        expect(results).to include(jim, john, numbers_person)
        expect(results).not_to include(billy_bob)
      end

      it 'phrase search with reversed terms returns no users' do
        results = User.search('"Bob Billy"')
        expect(results.to_a).to eq([])
        expect(results).not_to include(jim, john, billy_bob, numbers_person)
      end
    end

    context 'with search_type' do
      let(:search_type) { :simple }

      it 'simple last name query does not return expected users (mismatch between simple query and english tsvector)' do
        results = User.search('Jones')
        expect(results).not_to include(jim, john)
      end
    end

    context 'with any_word' do
      let(:any_word) { true }

      it 'returns any result matching any term' do
        results = User.search('Jeffers Jones')
        expect(results).to include(jim, john, billy_bob)
      end

      it 'returns any result matching phrase and term' do
        results = User.search('"Billy Bob" Jones')
        expect(results).to include(jim, john, billy_bob)
      end
    end

    context 'with prefix' do
      let(:prefix) { true }

      it 'returns results matching partial words' do
        results = User.search('Jon')
        expect(results).to include(jim, john)
      end

      it 'returns results matching partial numbers' do
        results = User.search('123')
        expect(results).to include(numbers_person)
      end
    end

    context 'without prefix' do
      let(:prefix) { false }

      it 'does not return results matching partial words' do
        results = User.search('Jo')
        expect(results.to_a).to eq([])
      end

      it 'does not return results matching partial numbers' do
        results = User.search('123')
        expect(results.to_a).to eq([])
      end

      it 'returns results matching whole words' do
        results = User.search('Jones')
        expect(results).to include(jim, john)
      end
    end

    context 'with ignore_accents' do
      let(:ignore_accents) { true }

      it 'returns results matching unaccented query' do
        results = User.search('Jönés')
        expect(results).to include(jim, john)
      end
    end
  end
end
