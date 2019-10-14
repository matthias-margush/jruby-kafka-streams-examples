# frozen_string_literal: true

require 'jbundler'
require 'kafka/topic'

module Kafka
  class Topology
    java_import java.lang.Runtime
    java_import java.lang.Thread
    java_import org.apache.kafka.streams.KafkaStreams
    java_import org.apache.kafka.streams.kstream.Consumed
    java_import org.apache.kafka.streams.kstream.Grouped
    java_import org.apache.kafka.streams.kstream.Produced
    java_import org.apache.kafka.streams.StreamsBuilder

    protected

    attr_accessor :streams_builder, :builder

    public

    def initialize(streams_builder = nil, props, &block)
      @streams_builder = streams_builder || StreamsBuilder.new
      @builder = @streams_builder
      @props = java.util.Properties.new
      @props.put_all(props)
      yield(self) if block
    end

    def self.with(topology_definition)
      Topology.new(topology_definition.kafka_config) { |builder| topology_definition.topology(builder) }
    end

    def wrap(builder)
      topology = Topology.new(@props)
      topology.streams_builder = @streams_builder
      topology.builder = builder
      topology
    end

    def method_missing(method, *args, &block)
      if @builder.respond_to?(method)
        wrap(@builder.send(method, *args, &block))
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      @builder.respond_to?(method_name, include_private)
    end

    def respond_to_missing?(*)
      super
    end

    def stream(topic)
      consumed = Consumed.with(topic.key_serde, topic.value_serde, nil, nil)
      wrap(@builder.stream(topic.name, consumed))
    end

    def to(topic)
      produced = Produced.with(topic.key_serde, topic.value_serde)
      wrap(@builder.to(topic.name, produced))
    end

    def group_by(repartition_name: nil, key_serde: nil, value_serde: nil, &block)
      grouping = Grouped.with(repartition_name, key_serde, value_serde)
      wrap(@builder.group_by(block, grouping))
    end

    def start(clean_up: false)
      kafka_streams = KafkaStreams.new(@streams_builder.build, @props)
      kafka_streams.clean_up if clean_up
      kafka_streams.start
    end

    def test_drive
      test_driver = TestDriver.new(@streams_builder, @props)
      yield(test_driver)
    ensure
      test_driver&.close
    end

    class TestDriver
      java_import org.apache.kafka.streams.TopologyTestDriver

      def initialize(streams_builder, props)
        @test_driver = TopologyTestDriver.new(streams_builder.build, props)
      end

      def produce(topic, key = nil, value, timestamp: 0)
        @test_driver.pipe_input(topic.message(key, value, timestamp))
      end

      def consume(topic)
        @test_driver.read_output(topic.name, topic.key_serde.deserializer, topic.value_serde.deserializer)
      end

      def close
        @test_driver.close
      end
    end
  end
end
