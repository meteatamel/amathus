import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';

class CenteredProgressIndicator extends StatelessWidget {
  const CenteredProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40.0,
            width: 40.0,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            Constants.LOADING_NEWS,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
