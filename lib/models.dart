import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class EmojiCategory {
  int num;
  List<Emoji> emojis = List();
  EmojiCategory(this.num);
}

class Emoji {
  String emoji, annotation, text_emoticon;
  EmojiCategory category;
  List<String> skins = List(), tags = List(), shortcodes = List();
  Emoji(
      {this.emoji,
      this.category,
      this.annotation = null,
      this.text_emoticon = null});

  static EmojiData _data;
  static int userSkinTone = 0;
  static Future<EmojiData> get emojis async {
    if (_data == null) {
      await _loadEmojis();
    }
    return _data;
  }

  static var _loading = false;
  static ReceivePort _receivePort;
  static Isolate _isolate;
  static _loadEmojis() async {
    if (_loading) return;
    _loading = true;
    _receivePort = ReceivePort();
    __loadJSONAndSpinIsolate();
    return _receivePort.first.then((data) {
      EmojiData d = data;
      _data = d;
      if (_isolate != null) {
        _isolate.kill();
        _isolate = null;
      }
    });
  }

  static __loadJSONAndSpinIsolate() async {
    String d =
        await rootBundle.loadString("packages/emojis/assets/emojis.json");
    print("loaded json string with legnth ${d.length}");
    final msg = _LoadMsg(_receivePort.sendPort, d);
    Isolate.spawn(__loadEmojis, msg).then((it) {
      if (_data != null) {
        it.kill();
      } else {
        _isolate = it;
      }
    });
    var prefs = await SharedPreferences.getInstance();
    userSkinTone = prefs.getInt("CI_EMOJI_SKINTONE") ?? 0;
  }

  static __loadEmojis(_LoadMsg msg) {
    List<dynamic> jsn = json.decode(msg.json);
    print("loaded json with length ${jsn.length}");
    Map<int, EmojiCategory> mcats = Map();
    List<Emoji> emojis = List();
    List<EmojiCategory> cats = List();
    for (Map<String, dynamic> m in jsn) {
      int catNum = m["group"];
      EmojiCategory cat = mcats[catNum];
      if (cat == null) {
        cat = EmojiCategory(catNum);
        cats.add(cat);
        mcats[cat.num] = cat;
      }
      var emoji = Emoji(
          emoji: m["unicode"],
          category: cat,
          annotation: m["annotation"],
          text_emoticon: m["emoticon"]);
      if (emoji.emoji.runes.length > 1) {
        continue;
      }
      if (m.containsKey("skins")) {
        for (Map<String, dynamic> skin in m["skins"]) {
          emoji.skins.add(skin["unicode"]);
        }
      }
      if (m.containsKey("tags")) {
        emoji.tags = (m["tags"] as List)
            .map((it) => it as String)
            .toList(growable: false);
      }
      if (m.containsKey("shortcodes")) {
        emoji.shortcodes = (m["shortcodes"] as List)
            .map((it) => it as String)
            .toList(growable: false);
      }
      emojis.add(emoji);
      cat.emojis.add(emoji);
    }
    msg.p.send(EmojiData(cats, emojis));
  }
}

class EmojiData {
  List<EmojiCategory> categories;
  List<Emoji> emojis;
  EmojiData(this.categories, this.emojis);
}

class _LoadMsg {
  SendPort p;
  String json;
  _LoadMsg(this.p, this.json);
}
