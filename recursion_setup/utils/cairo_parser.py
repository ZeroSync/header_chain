import struct


P = 2**251 + 17 * 2**192 + 1


class FeltsReader:
    def __init__(self, program_output):
        self.cursor = 0
        self.program_output = program_output

    def read(self):
        self.cursor += 1
        return self.program_output[self.cursor - 1]

    def read_n(self, felt_count):
        self.cursor += felt_count
        return self.program_output[self.cursor - felt_count: self.cursor]


def felts_to_hash(felts):
    res = 0
    for i in range(8):
        felt = felts[i]
        # Swap endianess
        felt = struct.unpack("<I", struct.pack(">I", felt))[0]
        res += pow(2**32, i) * felt
    return hex(res).replace('0x', '').zfill(64)


def felts_to_hex(felts):
    return list(map(felt_to_hex, felts))


def felt_to_hex(felt):
    """
    Convert felts to hex representation.
    Remove leading "0x", pad leading zeros to 32 bytes
    """
    hex_felt = hex(felt).replace('0x', '').zfill(64)
    if (int(hex_felt, 16) == 0):
        return "0"
    return hex_felt


def parse_cairo_output(cairo_output):
    # Split at line break. Then cut off all lines until the start of the
    # program output
    lines = cairo_output.split('\n')
    start_index = lines.index('Program output:') + 1
    end_index = lines.index('')

    lines = lines[start_index:end_index]
    lines = [x for x in lines if x.strip() != '']
    lines = map(int, lines)
    lines = map(lambda x: x if x >= 0 else (x + P) % P, lines)
    return list(lines)
