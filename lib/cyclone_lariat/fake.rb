# frozen_string_literal: true

module CycloneLariat
  class Fake
    def self.sns_publish_response(message)
      Aws::SNS::Types::PublishResponse.new.tap do |resp|
        resp.message_id = SecureRandom.uuid
        resp.sequence_number = rand(10).to_s if message.fifo?
      end
    end

    def self.sqs_send_message_result(message)
      Aws::SQS::Types::SendMessageResult.new.tap do |res|
        res.message_id = SecureRandom.uuid
        res.sequence_number = rand(10).to_s if message.fifo?
      end
    end
  end
end
