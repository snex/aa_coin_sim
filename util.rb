def print_number(num)
  num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def sell_penalty(weeks)
  (10 * ((1 / 1.0471285481) ** weeks) / 100.0)
end

def get_randoms_summing_to(target_sum, num_randoms, dist = Array.new(num_randoms, 1.0))
  denormalized = []
  orig_num_randoms = num_randoms

  if num_randoms > target_sum
    num_randoms = target_sum
  end

  while denormalized.sum != target_sum do
    normalized = []
    denormalized.clear
    num_randoms.times do |i|
      normalized.push(rand(0..dist[i]))
    end

    next if normalized.sum == 0
    denormalized = normalized.map { |n| (target_sum * (n / normalized.sum)).round }
  end

  if orig_num_randoms != num_randoms
    return (denormalized + Array.new(orig_num_randoms - num_randoms, 0)).shuffle
  end

  denormalized
end

def split_value(value, participants)
  # value - integer value to split among participants
  # participants - an array of Rational defining the percent of coins each participant is entitiled to. this MUST add to 1 exactly!
  # returns an array of values to distribute to each participant

  extras = 0
  values_returned = []

  participants.each do |participant|
    participant_value, extra = (value * participant).divmod(1)
    extras += extra
    values_returned.push(participant_value)
  end

  extras.to_i.times do |extra|
    idx = rand(0..(values_returned.size - 1))
    values_returned[idx] += 1
  end

  values_returned
end
