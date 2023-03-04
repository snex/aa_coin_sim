def print_money(dollars)
  "$#{dollars.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
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

    normalized_sum = normalized.sum
    denormalized = normalized.map { |n| (target_sum * (n / normalized_sum)).round }
  end

  if orig_num_randoms != num_randoms
    return (denormalized + Array.new(orig_num_randoms - num_randoms, 0)).shuffle
  end

  denormalized
end
