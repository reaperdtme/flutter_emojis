library emoji_keyboard;

import 'package:emojis/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/src/rendering/sliver_grid.dart';
import 'package:flutter/widgets.dart';

const _KEYBOARD_HEIGHT = 216.0;
const _EMOJI_HEIGHT = _KEYBOARD_HEIGHT / 5.0;

typedef EmojiTapped = bool Function(String);

class EmojiKeyboard extends StatefulWidget {
  EmojiTapped emojiTapped;
  var animated = true;
  EmojiKeyboard({this.emojiTapped, this.animated = true});

  @override
  State<StatefulWidget> createState() {
    return EmojiKeyboardState(
        emojiTapped: emojiTapped, animated: this.animated);
  }
}

class EmojiKeyboardState extends State<EmojiKeyboard>
    with SingleTickerProviderStateMixin {
  EmojiTapped emojiTapped;
  AnimationController _controller;
  var animated = true;
  var bottomPos = -_KEYBOARD_HEIGHT;
  var _spring = SpringDescription.withDampingRatio(
      mass: 1.0, stiffness: 500.0, ratio: 0.8);
  SpringSimulation _sim;
  final _startVelocity = 10.0;
  var _table;

  EmojiKeyboardState({this.emojiTapped, this.animated = true}) {
    bottomPos = this.animated ? -_KEYBOARD_HEIGHT : 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
        value: bottomPos, lowerBound: -1000.0, upperBound: 1000.0, vsync: this)
      ..addListener(_handleAnimate);
    _sim =
        ScrollSpringSimulation(_spring, -_KEYBOARD_HEIGHT, 0.0, _startVelocity);
    _controller.animateWith(_sim);
    _table = EmojiTable((emoji) {
      if (this.emojiTapped(emoji)) {
        _animateOut();
      }
    });
  }

  void _handleAnimate() {
    setState(() {
      bottomPos = _controller.value;
    });
  }

  void _animateOut() {
    _controller.stop();
    _controller.animateWith(ScrollSpringSimulation(
        _spring, 0.0, -_KEYBOARD_HEIGHT, -_startVelocity));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_handleAnimate);
    _controller = null;
    _table = null;
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Positioned(
        bottom: bottomPos,
        child: SizedBox(
          width: width,
          height: _KEYBOARD_HEIGHT,
          child: Material(color: Colors.grey, child: _table),
        ));
  }
}

class EmojiTable extends StatefulWidget {
  EmojiTapped emojiTapped;
  EmojiTable(this.emojiTapped);

  @override
  State<StatefulWidget> createState() {
    return EmojiTableState(emojiTapped);
  }
}

class EmojiTableState extends State<EmojiTable> {
  EmojiTapped emojiTapped;
  int skinEmojiIndex = -1;

  EmojiTableState(this.emojiTapped);

  String textForIndex(int index, EmojiData data) {
    for (var cat in data.categories) {
      var length = cat.emojis.length;
      var mod = length % 5;
      if (index < length) {
        return cat.emojis[index].emoji;
      } else if (index < length + 5 - mod) {
        return "";
      } else {
        index -= length + 5 - mod;
      }
    }
    return "";
  }

  int itemCount(EmojiData data) {
    int count = 0;
    for (var cat in data.categories) {
      var length = cat.emojis.length;
      var mod = length % 5;
      if (mod == 0) {
        count += length;
      } else {
        count += length - mod + 5;
      }
    }
    print("Count ${count}");
    return count;
  }

  void tappedIndex(int index, EmojiData data) {
    if (emojiTapped != null) {
      emojiTapped(textForIndex(index, data));
    }
  }

  void longPress(int index, EmojiData data) {}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Emoji.emojis,
        builder: (context, snapshot) {
          print(
              "Have Emojis? ${snapshot.hasData} ${snapshot.hasData ? "${snapshot.data.emojis.length}:${snapshot.data.categories.length}" : 0}");
          return GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.hasData ? itemCount(snapshot.data) : 0,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
              itemBuilder: (context, index) {
                return GestureDetector(
                    onTap: () => tappedIndex(index, snapshot.data),
                    onLongPress: () => longPress(index, snapshot.data),
                    child: SizedBox(
                        width: _EMOJI_HEIGHT,
                        height: _EMOJI_HEIGHT,
                        child: Text(
                          textForIndex(index, snapshot.data),
                          style: TextStyle(fontSize: 24.0),
                        )));
              });
        });
  }
}
