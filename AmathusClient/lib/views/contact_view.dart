import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: new Text(Constants.CONTACT), centerTitle: true),
        drawer: AppDrawer(),
        body: ContactForm());
  }
}

class ContactForm extends StatefulWidget {
  @override
  _ContactFormState createState() => new _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.all(10), children: [
      Text(Constants.CONTACT_INFO, style: TextStyle(fontSize: 20)),
      Divider(height: 15, thickness: 1),
      ListView(shrinkWrap: true, children: [
        ListTile(
            leading: Icon(Icons.email),
            title: Linkify(
              onOpen: (link) => _launchURL(link.url, context),
              text: Constants.APP_EMAIL,
              style: TextStyle(fontSize: 18),
            )),
        ListTile(
            leading: FaIcon(FontAwesomeIcons.facebook),
            title: Linkify(
                onOpen: (link) => _launchURL(link.url, context),
                text: Constants.URL_FACEBOOK,
                style: TextStyle(fontSize: 16))),
      ]),
      SizedBox(height: 20),
      Text(Constants.SEND_MESSAGE, style: TextStyle(fontSize: 20)),
      Divider(height: 15, thickness: 1),
      Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                    labelText: Constants.FIRST_LAST_NAME,
                    icon: Icon(Icons.person)),
                validator: _validateText,
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _bodyController,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: Constants.FEEDBACK,
                    icon: Icon(Icons.message)),
                maxLines: 5,
                validator: _validateText,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  label: Text(Constants.SEND),
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      await _sendEmail(context);
                    }
                  },
                ),
              ),
            ],
          ))
    ]);
  }

  String _validateText(String value) {
    return value.isEmpty ? Constants.NO_LEAVE_EMPTY : null;
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Email email = Email(
        body: _bodyController.text,
        subject: Constants.APP_NAME + " - " + _nameController.text,
        recipients: [Constants.APP_EMAIL]);

    String platformResponse;
    bool success;

    try {
      await FlutterEmailSender.send(email);
      success = true;
      platformResponse = 'Email gönderildi';
    } catch (error) {
      success = false;
      platformResponse = 'Email göndermede hata: $error.toString()';
    }

    _showSnackBar(platformResponse, context);

    if (success) {
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.text = '';
    _bodyController.text = '';
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackBar('Hata: $url', context);
    }
  }

  _showSnackBar(String text, BuildContext context) {
    if (mounted) {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }
}
