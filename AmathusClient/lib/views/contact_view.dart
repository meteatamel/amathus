import 'package:amathus/views/common/drawer.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactView extends StatelessWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.CONTACT),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: const ContactForm(),
    );
  }
}

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Constants.CONTACT_INFO,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const FaIcon(
                        FontAwesomeIcons.xTwitter,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                      title: Linkify(
                        onOpen: (link) => _launchURL(link.url, context),
                        text: Constants.URL_TWITTER,
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF0F2942),
                      ),
                      title: Linkify(
                        onOpen: (link) => _launchURL(link.url, context),
                        text: Constants.APP_EMAIL,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Constants.SEND_MESSAGE,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          labelText: Constants.FIRST_LAST_NAME,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: _validateText,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: Constants.FEEDBACK,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: _validateText,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2942),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: Text(Constants.SEND),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _sendEmail(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateText(String? value) {
    return (value == null || value.trim().isEmpty)
        ? Constants.NO_LEAVE_EMPTY
        : null;
  }

  Future<void> _sendEmail(BuildContext context) async {
    final subject = "${Constants.APP_NAME} - ${_nameController.text}";
    final body = _bodyController.text;

    String platformResponse;
    bool success = false;

    try {
      if (kIsWeb) {
        final mailtoUri = Uri(
          scheme: 'mailto',
          path: Constants.APP_EMAIL,
          queryParameters: {
            'subject': subject,
            'body': body,
          },
        );
        await launchUrl(mailtoUri);
        success = true;
        platformResponse = Constants.EMAIL_CLIENT_OPENED;
      } else {
        final email = Email(
          body: body,
          subject: subject,
          recipients: [Constants.APP_EMAIL],
        );
        await FlutterEmailSender.send(email);
        success = true;
        platformResponse = Constants.EMAIL_SENT;
      }
    } catch (error) {
      success = false;
      platformResponse = '${Constants.EMAIL_ERROR}: $error';
    }

    if (context.mounted) {
      _showSnackBar(platformResponse, context);
    }

    if (success) {
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.text = '';
    _bodyController.text = '';
  }

  Future<void> _launchURL(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _showSnackBar('${Constants.URL_ERROR}: $url', context);
    }
  }

  void _showSnackBar(String text, BuildContext context) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }
}
