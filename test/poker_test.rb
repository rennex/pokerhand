
require_relative "helper.rb"

require_relative "../pokerhand.rb"

include PokerHand

describe Suit do
  it "parses suits" do
    assert_equal Suit.parse("s"), Spades
    assert_equal Suit.parse("H"), Hearts
    assert_equal Suit.parse("c"), Clubs
    assert_equal Suit.parse("d"), Diamonds
    assert_equal Suit.parse(Spades), Spades
    assert_nil Suit.parse("x")
  end

  it "knows its name" do
    assert_equal "Clubs", Clubs.to_s
  end
end

describe Card do
  it "parses cards" do
    c = Card.new(5, "s")
    assert_equal 5, c.rank
    assert_equal Spades, c.suit

    c = Card.new("10d")
    assert_equal 10, c.rank
    assert_equal Diamonds, c.suit

    c = Card.new("Ac")
    assert_equal 14, c.rank
    assert_equal Clubs, c.suit

    c = Card.new("kD")
    assert_equal 13, c.rank
    assert_equal Diamonds, c.suit

    c = Card.new(2, Hearts)
    assert_equal 2, c.rank
    assert_equal Hearts, c.suit

    c = Card.new("Td")
    assert_equal 10, c.rank
    assert_equal Diamonds, c.suit
  end

  it "has a shortcut for .new" do
    assert_equal Card.new("2d"), Card["2d"]
  end

  it "raises exceptions" do
    assert_raises(ArgumentError) { Card.new() }
    assert_raises(ArgumentError) { Card.new(1, "d") }
    assert_raises(ArgumentError) { Card.new(2, "x") }
    assert_raises(ArgumentError) { Card.new(3, nil) }
    assert_raises(ArgumentError) { Card.new(4, []) }
    assert_raises(ArgumentError) { Card.new(55, Clubs) }
    assert_raises(ArgumentError) { Card.new("abc") }
    assert_raises(ArgumentError) { Card.new("5c ") }
  end

  it "has a working to_s" do
    assert_equal "Qd", Card.new(12, Diamonds).to_s
    assert_equal "10h", Card.new(10, "h").to_s
  end

  it "can be compared" do
    assert_operator Card.new("Qs"), :>, Card.new("8d")
    refute_operator Card.new("5c"), :<, Card.new("5d")
    refute_operator Card.new("5c"), :>, Card.new("5d")
    refute_operator Card.new("5c"), :==, Card.new("5d")
    assert_equal Card.new("7d"), Card.new(7, Diamonds)
  end

  it "can be sorted" do
    cards = [Card.new("As"), Card.new(5, "d")]
    refute_equal cards, cards.sort
  end

  it "can be used as a hash key" do
    h = {Card["8c"] => 2}
    assert_equal 2, h[Card.new("8c")]
  end
end


describe Hand do
  it "can parse cards" do
    hand = Hand.new("6c As Kd")
    assert_equal 3, hand.cards.size
    assert_equal Card.new("As"), hand.cards.max
  end

  it "finds straight flushes" do
    hand = Hand.new("As Ks 10s Js Qs")
    assert_equal Hand::ROYAL_FLUSH, hand.value
    assert_equal 14, hand.rank
    assert_nil hand.rank2
    assert_nil hand.kickers

    hand = Hand.new("4d 5d 2d 3d 6d")
    assert_equal Hand::STRAIGHT_FLUSH, hand.value
    assert_equal 6, hand.rank
    assert_nil hand.rank2
    assert_nil hand.kickers
  end

  it "finds straights" do
    hand = Hand.new("As Ks 10s Js Qd")
    assert_equal Hand::STRAIGHT, hand.value
    assert_equal 14, hand.rank
    assert_nil hand.rank2
    assert_nil hand.kickers

    hand = Hand.new("10d 8d 9d 6d 7s")
    assert_equal Hand::STRAIGHT, hand.value
    assert_equal 10, hand.rank
    assert_nil hand.rank2
    assert_nil hand.kickers
  end

  it "finds 5-high straights" do
    hand = Hand.new("As 5s 3d 2h 4d")
    assert_equal Hand::STRAIGHT, hand.value
    assert_equal 5, hand.rank
    assert_nil hand.rank2
    assert_nil hand.kickers
  end

  it "finds flushes" do
    hand = Hand.new("As Ks 10s Js 9s")
    assert_equal Hand::FLUSH, hand.value
    assert_equal 14, hand.rank
    assert_nil hand.rank2
    assert_equal [13, 11, 10, 9], hand.kickers

    hand = Hand.new("10d 8d 9d 6d 5d")
    assert_equal Hand::FLUSH, hand.value
    assert_equal 10, hand.rank
    assert_nil hand.rank2
    assert_equal [9, 8, 6, 5], hand.kickers
  end

  it "finds two pairs" do
    hand = Hand.new("As Ad 10s Js 10d")
    assert_equal Hand::TWO_PAIRS, hand.value
    assert_equal 14, hand.rank
    assert_equal 10, hand.rank2
    assert_equal [11], hand.kickers

    hand = Hand.new("2d 8d 9d 8s 9h")
    assert_equal Hand::TWO_PAIRS, hand.value
    assert_equal 9, hand.rank
    assert_equal 8, hand.rank2
    assert_equal [2], hand.kickers
  end

  it "finds quads" do
    hand = Hand.new("Jd 10s Js Jc Jh")
    assert_equal Hand::FOUR_OF_A_KIND, hand.value
    assert_equal 11, hand.rank
    assert_nil hand.rank2
    assert_equal [10], hand.kickers
  end

  it "finds full houses" do
    hand = Hand.new("8s 5s 8d 5d 8h")
    assert_equal Hand::FULL_HOUSE, hand.value
    assert_equal 8, hand.rank
    assert_equal 5, hand.rank2
    assert_nil hand.kickers
  end

  it "finds triplets" do
    hand = Hand.new("7d 7s 8d 5d 7h")
    assert_equal Hand::THREE_OF_A_KIND, hand.value
    assert_equal 7, hand.rank
    assert_nil hand.rank2
    assert_equal [8, 5], hand.kickers
  end

  it "finds a pair" do
    hand = Hand.new("2d Qh 9s 3s 3c")
    assert_equal Hand::PAIR, hand.value
    assert_equal 3, hand.rank
    assert_nil hand.rank2
    assert_equal [12, 9, 2], hand.kickers
  end

  it "finds a high card" do
    hand = Hand.new("8h 4c 2s 10d Jd")
    assert_equal Hand::HIGH_CARD, hand.value
    assert_nil hand.rank
    assert_nil hand.rank2
    assert_equal [11, 10, 8, 4, 2], hand.kickers
  end
end


describe Hand do
  it "compares various hands" do
    h1 = Hand.new("6h 8d 2c Ks Qs")   # high card
    h2 = Hand.new("10h Ah Qh Kh Jh")  # royal flush
    h3 = Hand.new("5c 2c Kc Jc 9c")   # flush
    h4 = Hand.new("Kd Ks 2h 2s Kh")   # full house
    h5 = Hand.new("9h Qs Qh 6c 6s")   # two pairs
    h6 = Hand.new("7d 7h Ac 7c 7s")   # quads
    h7 = Hand.new("Kd Ac 8s 9h Ah")   # pair
    h8 = Hand.new("5s 5h 8c 5d 9c")   # triplets
    h9 = Hand.new("8d 10d 7d 9d Jd")  # straight flush
    h10 = Hand.new("2c 5c 4c 3c Ad")  # straight
    assert_equal [h1, h7, h5, h8, h10, h3, h4, h6, h9, h2],
      [h1, h2, h3, h4, h5, h6, h7, h8, h9, h10].sort
  end

  # todo: test comparing similar hands down to the kicker level
end
