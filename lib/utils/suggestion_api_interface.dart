import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_info_s8_gpt/models/suggestion.dart';

class SuggestionApiInterface {
  static final SuggestionApiInterface instance =
      SuggestionApiInterface._internal();

  SuggestionApiInterface._internal();

  Future<void> putSuggestion(
      Suggestion suggestion, BuildContext context) async {
    String username = suggestion.username;
    String description = suggestion.description;
    String date = suggestion.date;
    final resp = await http.post(Uri.parse(
        "https://172.20.10.2:5000/suggestions?Username=$username&Suggestion=$description&Date=$date"));

    if (resp.statusCode != 201) {
      if (!context.mounted) return;
      return showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: const Text("Impossible de contacter l'API"),
                content: const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 50,
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ));
    }

    if (!context.mounted) return;
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('Merci pour votre suggestion !'),
              content: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 50,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ));
  }
}
