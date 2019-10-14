# frozen_string_literal: true

require 'jbundler'

module Kafka

  class Topic
    java_import org.apache.kafka.streams.test.ConsumerRecordFactory

    attr_reader :name, :key_serde, :value_serde

    def initialize(name:, key_serde:, value_serde:)
      @name = name
      @key_serde = key_serde
      @value_serde = value_serde
    end

    def message(key, value, timestamp = 0)
      @record_factory ||= ConsumerRecordFactory.new(@key_serde.serializer, @value_serde.serializer)
      @record_factory.create(@name, key, value, timestamp)
    end

    def to_s
      "Topic: #{@name}, Key Serde: #{@key_serde}, Value Serde: #{@value_serde}"
    end
  end
end
