from dahuffman import HuffmanCodec

# Read asnwer and guess from text files

def load_word_list(file_name):
    with open(file_name, 'r') as f:
        word_list = f.read()
        word_list = word_list.split('\n')    
        word_list = [word.lower().strip() for word in word_list]
    # remove empty words
    word_list = [word for word in word_list if len(word) > 0]
    return word_list

answers = load_word_list('dta/answer.txt')
guesses = load_word_list('dta/guess.txt')

word_list = answers + guesses

# Character frequency
char_freq = {}
max_freq = 0
for word in word_list:
    for char in word:
        if char not in char_freq:
            char_freq[char] = 1
        else:
            char_freq[char] += 1
        if max_freq < char_freq[char]:
            max_freq = char_freq[char]
# Artificially increase the frequency of '-' to make it the most frequent character i.e. 0
char_freq['-'] = max_freq + 1

# Huffman encoding
codec = HuffmanCodec.from_frequencies(char_freq, eof='-')
code_table = codec.get_code_table()

def char_to_bits(char):
    bits, code = code_table[char]
    return ("{0:0"+str(bits)+"b}").format(code)


# Print the code table
word_by_code = {}
code_by_word = {}
for word in word_list:    
    code = ''.join(map(char_to_bits, word))    
    # append zeros to make it modulo 8
    code += '0' * (8 - len(code) % 8)
    if word_by_code.get(code) is not None:
        raise Exception(f"Duplicate code {code} for {word} and {word_by_code[code]}")
    word_by_code[code] = word
    if code_by_word.get(word) is not None:
        raise Exception(f"Duplicate word {word} for {code} and {code_by_word[word]}")
    code_by_word[word] = code


BANK_SIZE = 0x4000

bank = 0
global_offset = 0
bank_offset = BANK_SIZE

with open('src/word_list.asm', 'w') as f:

    def prcoess_words(words, label):
        global bank
        global global_offset
        global bank_offset

        internal_bank = 0
        word_len = None

        # sort words by code length and code 
        words = sorted(words, key=lambda word: (len(code_by_word[word]), code_by_word[word]))

        for word in words:
            code = code_by_word[word]
            chunks = [code[i:i+8] for i in range(0, len(code), 8)]
            size = len(chunks)

            if bank_offset + size > BANK_SIZE:
                bank += 1
                bank_offset = 0
                f.write(f"\n\nSECTION \"WordListBank{bank}\", ROMX, BANK[{bank}]\n")                         
                if bank == 1:   
                    f.write(f"WordList::\n")
                           

            # prefix chunks with %
            chunks = ['%'+chunk for chunk in chunks]
            chunks = ', '.join(chunks)            
            ords = ', '.join( [str(ord(char) - ord('a')) for char in word] )
            character_codes = ', '.join(map(char_to_bits, word))
            f.write(f"WordList{label}_{word.upper()}:\t")
            f.write("DB {0:60s}\t; {1}   {2}  dec: {3:20s} code: {4} \n".format(chunks, word, label, ords, character_codes))
            bank_offset += size
            global_offset += size

    prcoess_words(answers, "Asnwer")    
    prcoess_words(guesses, "Guess")
