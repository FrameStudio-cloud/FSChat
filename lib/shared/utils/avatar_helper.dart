import 'package:flutter/material.dart';

const _baseUrl = 'https://api.dicebear.com/9.x/adventurer/svg';

ImageProvider getAvatar(String? photoUrl, String name) {
  if (photoUrl != null && photoUrl.isNotEmpty) {
    return NetworkImage(photoUrl);
  }
  final seed = Uri.encodeComponent(name.isNotEmpty ? name : 'User');
  return NetworkImage('$_baseUrl?seed=$seed');
}

Widget avatarWidget({
  double radius = 16,
  String? photoUrl,
  String name = '',
}) {
  return CircleAvatar(
    radius: radius,
    backgroundImage: getAvatar(photoUrl, name),
    onBackgroundImageError: (_, __) {},
  );
}
