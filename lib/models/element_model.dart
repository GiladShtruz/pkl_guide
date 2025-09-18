
class ElementModel {
  final String text;
  final bool isUserElement;

  ElementModel(this.text, this.isUserElement);

  Map<String, dynamic> toJson() {
    return {
      'element': text,
      'isUserElement': isUserElement,
    };
  }

  factory ElementModel.fromJson(Map<String, dynamic> json) {
    return ElementModel(
      json['element'],
      json['isUserElement'],
    );
  }




}