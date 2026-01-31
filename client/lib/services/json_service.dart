class TcpMessage {
  String name;
  String content;

  TcpMessage(this.name, this.content);

  factory TcpMessage.fromJson(Map<String, dynamic> json) {
    return TcpMessage(json['name'], json['content']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'content': content};
  }
}
