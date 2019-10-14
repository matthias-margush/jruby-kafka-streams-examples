# frozen_string_literal: true

$LOAD_PATH.unshift 'lib'

namespace :wordcount do
  desc 'Create topics for the wordcount kafka streams example.'
  task :create_topics do
    sh 'kafka-topics --create --topic streams-plaintext-input --zookeeper localhost:2181 --partitions 1 --replication-factor 1'
    sh 'kafka-topics --create --topic streams-wordcount-output --zookeeper localhost:2181 --partitions 1 --replication-factor 1'
  end

  desc 'Generate and publish seed data to the wordcount input topic.'
  task :seed do
    sh 'echo "hello kafka streams\nall streams lead to kafka\njoin kafka summit\n" | kafka-console-producer --broker-list localhost:9092 --topic streams-plaintext-input'
  end

  desc 'Run the wordcount topology.'
  task :run do
    require 'examples/streams/word_count'
    Kafka::Topology.with(Examples::Streams::WordCount).start(clean_up: true)
  end
end
