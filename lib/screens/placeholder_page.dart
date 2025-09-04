import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 420,
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}
