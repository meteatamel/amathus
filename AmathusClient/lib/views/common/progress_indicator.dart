import 'package:flutter/material.dart';

class CenteredProgressIndicator extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
            height: 200.0,
            width: 200.0,
            child: CircularProgressIndicator())
    );
  }
}