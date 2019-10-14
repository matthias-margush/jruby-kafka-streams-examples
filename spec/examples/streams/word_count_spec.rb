# frozen_string_literal: true

require 'examples/streams/word_count'

describe Examples::Streams::WordCount do
  it '' do
    WordCount = Examples::Streams::WordCount
    topology = Kafka::Topology.with(WordCount)
    topology.test_drive do |test_driver|
      test_driver.produce(WordCount::INPUT_TOPIC, 'Hello')
      result = test_driver.consume(WordCount::OUTPUT_TOPIC)
      expect(result.key).to eq('Hello')
      expect(result.value).to eq(1)
    end
  end
end
