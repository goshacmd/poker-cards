class Card
  attr_reader :value, :suit

  VALUES = %w(2 3 4 5 6 7 8 9 T J Q K A)
  SUITS = %w(S H C D)

  def self.build(str)
    str.upcase!

    value = str[0]
    suit = str[1]

    new(value, suit)
  end

  def initialize(value, suit)
    @value = value
    @suit = suit
  end

  def value_code
    VALUES.index value
  end

  def inspect
    [value, suit].join
  end
end

class Hand
  attr_reader :cards

  def initialize(cards)
    raise ArgumentError unless cards.size == 5

    @cards = cards.sort_by(&:value_code).reverse
  end

  def same_suit?
    suits.uniq.size == 1
  end

  def sequential?
    seq = values

    value_diffs = seq.each_with_index.map do |value, index|
      if index == 0
        1
      else
        previous = seq[index - 1]
        previous - value
      end
    end

    value_diffs.all? { |v| v == 1 }
  end

  def pairs
    values.combination(2).select { |(a, b)| a == b }
  end

  def trips
    values.combination(3).select { |(a, b, c)| a == b  && b == c }
  end

  def fours
    values.combination(4).select { |(a, b, c, d)| a == b && b == c && c == d }
  end

  def suits
    cards.map(&:suit)
  end

  def values
    cards.map(&:value_code)
  end

  def inspect
    "H(#{cards.map(&:to_s).join(' ')})"
  end
end

class Combination
  attr_reader :hand

  COMBINATIONS = []

  class << self
    def name(name = nil)
      @name = name if name
      @name
    end

    def match_block(&block)
      @block = block if block_given?
      @block
    end

    def combination(c_name, &block)
      COMBINATIONS << Class.new(Combination) do
        name c_name
        match_block(&block)
      end
    end

    def combinations_for_hand(hand)
      COMBINATIONS.map { |c| c.new(hand) }
    end
  end

  def initialize(hand)
    @hand = hand
  end

  def matches?
    instance_exec(&self.class.match_block)
  end

  def inspect
    "C(#{self.class.name} - #{hand})"
  end

  combination(:high_card) { true }
  combination(:one_pair) { hand.pairs.size > 0 }
  combination(:two_pair) { hand.pairs.size > 1 }
  combination(:three_of_a_kind) { hand.trips.size > 0 }
  combination(:straight) { hand.sequential? }
  combination(:flush) { hand.same_suit? }
  combination(:full_house) { hand.trips.size > 0  && hand.pairs.size > 0 }
  combination(:four_of_a_kind) { hand.fours.size > 0 }
  combination(:straight_flush) { hand.same_suit? && hand.sequential? }
end

class CombinationDetector
  attr_reader :cards

  def initialize(cards)
    @cards = cards
  end

  def hands
    @hands ||= cards.combination(5).map { |c| Hand.new(c) }
  end

  def matched_combinations
    hands.map do |hand|
      [hand, Combination.combinations_for_hand(hand).select(&:matches?)]
    end
  end
end
