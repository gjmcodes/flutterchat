import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  TextComposer(this.sendMessage);

  final Function({String text, File imgFile}) sendMessage;
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  TextEditingController _textEditingController = TextEditingController();
  bool _isComposing = false;
  final _imgPicker = ImagePicker();

  _sendMessage(String text) {
    widget.sendMessage(text: text);
    _textEditingController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () async {
                final imgFile =
                    await _imgPicker.getImage(source: ImageSource.camera);
                if (imgFile == null) return;

                widget.sendMessage(imgFile: File(imgFile.path));
              }),
          Expanded(
              child: TextField(
            controller: _textEditingController,
            decoration:
                InputDecoration.collapsed(hintText: 'Enviar uma mensagem.'),
            onChanged: (text) {
              setState(() {
                _isComposing = text.isNotEmpty;
              });
            },
            onSubmitted: (text) {
              _sendMessage(text);
            },
          )),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isComposing
                ? () {
                    _sendMessage(_textEditingController.text);
                  }
                : null,
          )
        ],
      ),
    );
  }
}
