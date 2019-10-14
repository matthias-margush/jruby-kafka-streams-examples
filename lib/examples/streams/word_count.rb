# frozen_string_literal: true

require 'kafka'
require 'tmpdir'

module Examples
  module Streams
    class WordCount
      INPUT_TOPIC = Kafka::Topic.new(name: 'streams-plaintext-input',
                                     key_serde: Kafka::Serdes.String,
                                     value_serde: Kafka::Serdes.String)
      OUTPUT_TOPIC = Kafka::Topic.new(name: 'streams-wordcount-output',
                                      key_serde: Kafka::Serdes.String,
                                      value_serde: Kafka::Serdes.Long)

      def initialize
        @topology = Kafka::Topology.new(WordCount.kafka_config) { |builder| WordCount.topology(builder) }
      end

      def self.kafka_config
        { 'application.id' => 'wordcount-example-10',
          'client.id' => 'wordcount-example-client-10',
          'bootstrap.servers' => 'localhost:9092',
          'default.key.serde' => Kafka::Serdes.String.java_class,
          'default.value.serde' => Kafka::Serdes.String.java_class,
          'state.dir' => Dir.mktmpdir }
      end

      def start
        @topology.start
      end

      def self.topology(builder)
        text_lines = builder.stream(INPUT_TOPIC)
        word_counts = text_lines.flat_map_values { |value| puts 'split'; value.split(/\W+/) }
                        .group_by { |_key, word| word }
                        .count
        word_counts.to_stream.to(OUTPUT_TOPIC)
      end
    end
  end
end
