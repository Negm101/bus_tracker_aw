// ignore_for_file: use_key_in_widget_constructors, must_be_immutable

import 'dart:convert';

import 'package:bus_tracker_aw/models/announcment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

class AnnDetailsPage extends StatelessWidget {
  AnnDetailsPage({required this.announcement});
  Announcement announcement;
  final FocusNode _focusNode = FocusNode();
  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(announcement.title!),
        foregroundColor: Colors.blueGrey,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(5),
          child: QuillEditor(
            focusNode: _focusNode,
            scrollController: ScrollController(),
            scrollable: true,
            padding: EdgeInsets.zero,
            autoFocus: false,
            expands: true,
            showCursor: false,
            controller: QuillController(
                document:
                    Document.fromJson(jsonDecode(announcement.bodyDelta!)),
                selection: const TextSelection.collapsed(offset: 0)),
            readOnly: true,
          ),
        ),
      ),
    );
  }
}
