require 'opus-ruby'
require 'json'

VERSION = '2.0.0'

# Generate a 10-second long file, or however many seconds specified by console arguments
duration = ARGV[0]&.to_i || 10

# Generate a 60-sample long sine wave with an amplitude of 4095, as an array of integers
def wave
  [*0..60].map do |e|
    (4095 * Math.sin(e * Math::PI / 60)).round
  end
end

# Our wave needs to be 3840 bytes long, so multiply it by 64 (3840 / 60)
long_wave = wave * 64

# Pack the long_wave into a string
packed = long_wave.pack('s<*')

SAMPLE_RATE = 48_000 # Hz
FRAME_SIZE = 960 # bytes
CHANNELS = 2
BITRATE = 64_000
encoder = Opus::Encoder.new(SAMPLE_RATE, FRAME_SIZE, CHANNELS)
encoder.bitrate = BITRATE
packet = encoder.encode(packed, packed.length)

# Create the dca file
file = File.open('sine.dca', 'w')

DCA_MAGIC = 'DCA1'.freeze
file.write(DCA_MAGIC)

metadata = {
  dca: {
    version: 1,
    tool: {
      name: 'sine.dca',
      version: VERSION,
      url: 'https://github.com/meew0/sine.dca',
      author: 'meew0'
    },
    info: {
      title: 'Sine Wave',
      artist: 'Mathematics',
      album: 'Trigonometry',
      genre: 'math',
      comments: "#{duration}-second sine wave",
      cover: nil
    },
    origin: {
      source: 'generated'
    },
    opus: {
      mode: 'music',
      sample_rate: SAMPLE_RATE,
      frame_size: FRAME_SIZE,
      abr: BITRATE,
      channels: CHANNELS
    },
    extra: {}
  }
}
metadata_json = metadata.to_json
file.write([metadata_json.length].pack('l<')) # Metadata header
file.write(metadata_json) # Metadata

packets = duration * 50

packets.times do
  file.write([packet.length].pack('s<')) # Packet header
  file.write(packet) # Packet
end