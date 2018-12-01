class CipherTools
=begin
  Use:
    load 'lib/cipher_tools.rb'
    enc_num_list = CipherTools.xor_encrypt 'abcde', 'yz' # [24, 24, 26, 30, 28]
    all_guesses = []
    CipherTools.guess_key(enc_num_list, 2) { |guesses| all_guesses += guesses }
    all_guesses
=end
  NON_ENGLISH_CHARS = %r{[^A-Za-z0-9 .,!"'$();]+}.freeze
  NO_SPACE_AROUND_PUNC = %r{([.,!"'$)]\w)|(\w\()|(\w\d\w)}


  class << self
    # TODO: method should receive text string and not array of numbers
    def xor_decrypt(ascii_list, key)
      key_chars = key.chars
      ascii_list.map do |num|
        num
            .public_send('^', key_chars.rotate!.last.ord)
            .chr
      end.join
    end

    # TODO: method should return encrypted text and not array of numbers
    def xor_encrypt(text, key)
      key_chars = key.chars
      text.chars.map do |char|
        char.ord
            .public_send('^', key_chars.rotate!.last.ord)
      end

    end

    # TODO: !! this method might run for a very long time (for key size 6+), do not call directly from client,
    # TODO: !! run as background job, save on redis and do polling
    def guess_key(encrypted_num_list, key_size, bulk_size = 1000, &block)
      # TODO: my first thought was to generate all keys beforehand, but ruby couldn't handle such a big array
      # TODO: (keys count for size 6: 309 Million, size 10: 141 Trillion)
      # TODO: and it reported "NoMemoryError: failed to allocate memory", obviously it's a huge waste of memory, so
      # TODO: i switched to changing keys dynamically
      # keys = generate_keys key_size
      key_to_start = 'a' * key_size
      key_to_end = 'z' * key_size
      key_to_start_new = nil

      loop do
        key_to_start = key_to_start_new.dup if key_to_start_new
        guesses, key_to_start_new = guess_key_bulk encrypted_num_list, key_to_start, bulk_size

        # TODO: uncomment to see progress
        # puts "guess count: #{guesses.size}, key range: #{key_to_start}..#{key_to_end}", "sample guesses: #{guesses.take(10)}", '=' * 20

        block.call guesses if block_given?

        # TODO: store on redis, gc memory
        guesses = nil
        break if key_to_start_new == key_to_end
      end
    end

    # FIXME: takes too long, where's the prob?
    def guess_key_bulk(text_as_num_list, key_to_start, bulk_size)
      key = key_to_start.dup
      last_key = nil
      key_to_end = 'z' * key_to_start.size

      guesses = []
      (1..bulk_size).each do |_idx|
        guess_dec = xor_decrypt(text_as_num_list, key)
        last_key = key.dup
        guesses.push([last_key, guess_dec]) if all_tests_ok?(guess_dec) # TODO: do we need a stricter filter?
        break if last_key == key_to_end

        key.next!
      end

      [guesses, last_key]
    end

    def text_to_num_list(text)
      text.chars.map &:ord
    end

    def num_list_to_text(list)
      list.map(&:chr).join
    end

    def all_tests_ok?(text)
      english_chars_only?(text) #&&
          # !missing_space_around_punc?(text) # TODO: filter disabled since provided text is not grammar correct :D
    end

    def english_chars_only?(text)
      text !~ NON_ENGLISH_CHARS
    end

    def missing_space_around_punc?(text)
      text =~ NO_SPACE_AROUND_PUNC
    end

    def spec_assert_enc_dec(text = 'abcde', key = 'yz')
      xor_decrypt(xor_encrypt(text, key), key) == text
    end

    def spec_assert_contains_text(text = 'abcde', key = 'yz')
      enc_num_list = CipherTools.xor_encrypt text, key

      success = false
      CipherTools.guess_key enc_num_list, key.size do |guesses|
        success = guesses.any? {|_key, guess| guess == text} unless success
      end
      success
    end

    # Run with:
    #   Benchmark.measure { CipherTools.test 'abcde', 'yzyzyz' }
    # Time to run:
    #   key size 5: ~45s
    #   key size 6: ~20min
    #
    def test(text = 'abcde', key = 'yz')
      enc_num_list = CipherTools.xor_encrypt text, key
      all_guesses = []
      CipherTools.guess_key enc_num_list, key.size do |guesses|
        all_guesses += guesses
        print '.'
      end
      all_guesses

    end
  end
end