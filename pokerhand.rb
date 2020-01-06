
module PokerHand

  class Card
    include Comparable

    RANKS = {"T" => 10, "J" => 11, "Q" => 12, "K" => 13, "A" => 14}.freeze
    RANKS_TO_S = RANKS.invert
    RANKS_TO_S.delete(10)

    attr_reader :rank, :suit

    def initialize(rank, suit = nil)
      case rank
      when String
        if rank =~ /\A((\d+)|([TJQKA]))([shcd])\z/i
          @rank = $3 ? RANKS[$3.upcase] : $2.to_i
          @suit = Suit.parse($4)
        else
          raise ArgumentError, "invalid card string: '#{rank}'"
        end

      when Integer
        if (2..14).include? rank
          @rank = rank
        else
          raise ArgumentError, "rank '#{rank}' out of range"
        end
        @suit = Suit.parse(suit)

      else
        raise ArgumentError, "unsupported rank argument (#{rank.class})"
      end

      unless @suit.is_a? Suit
        raise ArgumentError, "invalid suit (#{@suit.inspect})"
      end
    end

    # alternate way to create cards: Card["5s"]
    def self.[](*args)
      new(*args)
    end

    def self.rank_to_s(rank)
      RANKS_TO_S[rank] || rank.to_s
    end

    def to_s
      Card.rank_to_s(@rank) + @suit.letter
    end

    # ignore suit when comparing order
    def <=>(other)
      @rank <=> other.rank
    end

    # consider suit as well as rank when testing for equality
    def ==(other)
      @rank == other.rank && @suit == other.suit
    end
    alias eql? ==

    def hash
      @rank.hash ^ @suit.hash
    end
  end


  class Suit
    attr_reader :letter
    @@suits = {}

    class << self
      private :new
      def create(name)
        suit = new(name)
        @@suits[suit.letter] = suit
      end

      def parse(letter)
        return letter if letter.is_a? Suit
        if letter.respond_to? :downcase
          @@suits[letter.downcase]
        else
          raise ArgumentError, "can't parse suit '#{letter}'"
        end
      end
    end

    def initialize(name)
      @name = name
      @letter = name[0].downcase
      # set e.g. PokerHand::Clubs to equal the suit named "Clubs"
      self.class.superclass.const_set(name, self)
    end

    def to_s
      @name
    end
  end

  Suit.create("Spades")
  Suit.create("Hearts")
  Suit.create("Clubs")
  Suit.create("Diamonds")


  class Hand
    include Comparable

    hands = ["royal flush", "straight flush", "four of a kind", "full house",
      "flush", "straight", "three of a kind", "two pairs", "pair", "high card"]

    HAND_TO_S = {}
    hands.each_with_index do |name, i|
      num = hands.size - i
      const_name = name.upcase.gsub(/ /, "_")
      const_set(const_name, num)
      HAND_TO_S[num] = name
    end

    attr_reader :cards
    attr_reader :value, :suit, :rank, :rank2, :kickers

    def initialize(hand)
      case hand
      when String
        @cards = hand.split(" ").map {|card| Card.new(card) }
      when Array
        @cards = hand
      else
        raise ArgumentError
      end

      @suit = @rank = @rank2 = nil

      evaluate if cards.size == 5
    end

    def evaluate
      suits = @cards.map(&:suit)
      ranks = @cards.map(&:rank).sort.reverse
      @rank = ranks.max

      if suits.uniq.size == 1
        flush = true
        @value = FLUSH
        @suit = suits.first
        @kickers = ranks[1..-1]
      end

      min = ranks.min
      if ranks.map {|r| r - min } == [4, 3, 2, 1, 0] || ranks == [14, 5, 4, 3, 2]
        straight = true
        @value = STRAIGHT
        # handle the one case where an ace counts as 1
        if @rank == 14 && min == 2
          @rank = 5
        end
      end

      if flush && straight
        if @rank == 14
          @value = ROYAL_FLUSH
        else
          @value = STRAIGHT_FLUSH
        end
        @kickers = nil
      end

      # if it's a flush and/or straight, we're done
      return if flush || straight

      # find pairs, trips, quads
      counts = Hash.new(0)
      ranks.each do |r|
        counts[r] += 1
      end

      # check for two pairs first, because it breaks "dupes"
      pairs = counts.find_all {|rank, count| count == 2 }.sort
      if pairs.size == 2
        @value = TWO_PAIRS
        @rank  = pairs[1][0]
        @rank2 = pairs[0][0]

        @kickers = ranks
        @kickers.delete(@rank)
        @kickers.delete(@rank2)
        return
      end

      dupes = counts.invert
      dupes.delete(1)
      # now dupes[4] = the rank of the quads, if any.
      # dupes[3] = the trips, and dupes[2] = the pair

      # set the rank from the quads / trips / pair
      @rank = dupes[dupes.keys.max]

      # find any singles
      @kickers = counts.find_all {|rank, count| count == 1 }
                  .map {|rank, count| rank }.sort.reverse

      @value =
        if dupes[4]
          FOUR_OF_A_KIND
        elsif dupes[3] && dupes[2]
          @rank2 = dupes[2]
          @kickers = nil
          FULL_HOUSE
        elsif dupes[3]
          THREE_OF_A_KIND
        elsif dupes[2]
          PAIR
        else
          HIGH_CARD
        end
    end

    def <=>(other)
      ret = @value <=> other.value
      ret = @rank <=> other.rank if ret == 0
      ret = @rank2 <=> other.rank2 if ret.to_i == 0
      ret = @kickers <=> other.kickers if ret.to_i == 0
      ret.to_i
    end

    def to_s
      ret = HAND_TO_S[@value]
      dupes = [@rank, @rank2].compact.map {|r| Card.rank_to_s(r) + "s" }
      extra = case @value
              when STRAIGHT_FLUSH, FLUSH, STRAIGHT
                "#{Card.rank_to_s(@rank)} high"
              when FULL_HOUSE
                dupes.join(" full of ")
              when HIGH_CARD
                Card.rank_to_s(@kickers.first)
              else
                dupes.join(" and ")
              end
      ret += " (#{extra})" if extra != ""
      ret
    end

  end
end
