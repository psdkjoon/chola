import 'dart:math';

import 'package:chola/math/answer.dart';
import 'package:chola/practice/practice_config.dart';

class Question {
  const Question({
    required this.topic,
    required this.text,
    required this.answer,
    this.prompt = '',
    this.work = const <String>[],
    this.review = false,
  });

  final String topic;
  final String prompt;
  final String text;
  final Answer answer;
  final List<String> work;
  final bool review;

  Question asReview() => Question(
        topic: topic,
        text: text,
        answer: answer,
        prompt: prompt,
        work: work,
        review: true,
      );
}

class Attempt {
  const Attempt({
    required this.question,
    required this.given,
    required this.correct,
    required this.millis,
  });

  final Question question;
  final String given;
  final bool correct;
  final int millis;
}

class Gen {
  Gen(this.config, this.d, this.r);

  final PracticeConfig config;
  final int d;
  final Random r;

  int n(int lo, int hi) => lo + r.nextInt(hi - lo + 1);

  int nz(int lo, int hi) {
    var v = 0;
    while (v == 0) {
      v = n(lo, hi);
    }
    return v;
  }

  int sign() => r.nextBool() ? 1 : -1;

  bool chance([int outOf = 2]) => r.nextInt(outOf) == 0;

  T pick<T>(List<T> items) => items[r.nextInt(items.length)];

  int by(int easy, int medium, int hard) =>
      d == 1 ? easy : (d == 2 ? medium : hard);
}
