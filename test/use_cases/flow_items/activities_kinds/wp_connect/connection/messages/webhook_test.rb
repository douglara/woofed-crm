require "test_helper"
require 'sidekiq/testing'

class FlowItems::ActivitiesKinds::WpConnect::Messages::ReceiveTest < ActiveSupport::TestCase
  test "should valid message" do
    wp_connect = FlowItems::ActivitiesKinds::WpConnect.create(
      session: ENV['WP_CONNECT_SESSION'],
      token: ENV['WP_CONNECT_TOKEN'],
      endpoint_url: ENV['WP_CONNECT_ENDPOINT'],
      enabled: true,
      secretkey: ENV['WP_CONNECT_SECRET_KEY']
    )

    contact = Contact.create(
      full_name: 'Douglas',
      phone: '41996910256'
    )

    event = {
      "event": "onmessage",
      "session": "#{ENV['WP_CONNECT_SESSION']}",
      "id": "false_554196910256@c.us_3EB0D454A12B14E80020",
      "body": "msg 2",
      "type": "chat",
      "t": 1634418613,
      "notifyName": "Douglas Lara",
      "from": "554196910256@c.us",
      "to": "554199895525@c.us",
      "self": "in",
      "ack": 1,
      "isNewMsg": true,
      "star": false,
      "recvFresh": true,
      "isFromTemplate": false,
      "broadcast": false,
      "mentionedJidList": [],
      "isVcardOverMmsDocument": false,
      "isForwarded": false,
      "labels": [],
      "ephemeralOutOfSync": false,
      "productHeaderImageRejected": false,
      "isDynamicReplyButtonsMsg": false,
      "isMdHistoryMsg": false,
      "requiresDirectConnection": false,
      "chatId": "554196910256@c.us",
      "fromMe": false,
      "sender": {
        "id": "554196910256@c.us",
        "name": "Douglas Lara",
        "shortName": "Douglas",
        "pushname": "Douglas Lara",
        "type": "in",
        "labels": [],
        "isContactSyncCompleted": 1,
        "formattedName": "Douglas Lara",
        "isMe": false,
        "isMyContact": true,
        "isPSA": false,
        "isUser": true,
        "isWAContact": true,
        "profilePicThumbObj": {
          "eurl": "https://pps.whatsapp.net/v/t61.24694-24/71402483_541867693209621_6132535853726369692_n.jpg?ccb=11-4&oh=b61d9c7a93b0a3c793199e7ad2e58b65&oe=61707395",
          "id": "554196910256@c.us",
          "img": "https://pps.whatsapp.net/v/t61.24694-24/s96x96/71402483_541867693209621_6132535853726369692_n.jpg?ccb=11-4&oh=68c44843e6c8d5c984879a30f8625e1a&oe=616FA060",
          "imgFull": "https://pps.whatsapp.net/v/t61.24694-24/71402483_541867693209621_6132535853726369692_n.jpg?ccb=11-4&oh=b61d9c7a93b0a3c793199e7ad2e58b65&oe=61707395",
          "raw": nil,
          "tag": "1576994420"
        },
        "msgs": nil
      },
      "timestamp": 1634418613,
      "content": "msg 2",
      "isGroupMsg": false,
      "isMedia": false,
      "isNotification": false,
      "isPSA": false,
      "mediaData": {}
    }
  
    assert FlowItem.all.count, 0
    result = FlowItems::ActivitiesKinds::WpConnect::Messages::Webhook.call(event)

    assert result.key?(:ok), true
    assert FlowItem.all.count, 1
  end
end
