import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:skinsight/features/scan/data/skin_live_face_guide.dart';

void main() {
  group('SkinLiveFaceGuide Unit Tests', () {
    late SkinLiveFaceGuide guide;

    setUp(() {
      guide = SkinLiveFaceGuide(requiredStableMs: 500);
    });

    test('no face returns noFace status', () {
      final feedback = guide.evaluate(
        faces: const [],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.noFace));
      expect(feedback.isRelatable, isFalse);
      expect(feedback.isReadyToCapture, isFalse);
    });

    test('multiple faces returns multipleFaces status', () {
      final face1 = Face(
        boundingBox: const Rect.fromLTWH(100, 200, 200, 250),
        landmarks: const {},
        contours: const {},
      );
      final face2 = Face(
        boundingBox: const Rect.fromLTWH(400, 200, 200, 250),
        landmarks: const {},
        contours: const {},
      );

      final feedback = guide.evaluate(
        faces: [face1, face2],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.multipleFaces));
      expect(feedback.isRelatable, isFalse);
    });

    test('face too far returns tooFar status', () {
      // Width = 100 / 720 = 0.138 (< 0.28)
      final smallFace = Face(
        boundingBox: const Rect.fromLTWH(310, 500, 100, 120),
        landmarks: const {},
        contours: const {},
      );

      final feedback = guide.evaluate(
        faces: [smallFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.tooFar));
      expect(feedback.message, contains('Dekatkan wajah'));
    });

    test('face too close returns tooClose status', () {
      // Width = 650 / 720 = 0.90 (> 0.82)
      final hugeFace = Face(
        boundingBox: const Rect.fromLTWH(35, 200, 650, 800),
        landmarks: const {},
        contours: const {},
      );

      final feedback = guide.evaluate(
        faces: [hugeFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.tooClose));
      expect(feedback.message, contains('Jauhkan sedikit'));
    });

    test('face off center returns offCenter status', () {
      // Left = 20, width = 320, center.dx = 180 / 720 = 0.25 (target is 0.5, dx = 0.25 > 0.16)
      // Height = 480 / 1280 = 0.375
      final offCenterFace = Face(
        boundingBox: const Rect.fromLTWH(20, 350, 320, 480),
        landmarks: const {},
        contours: const {},
      );

      final feedback = guide.evaluate(
        faces: [offCenterFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.offCenter));
      expect(feedback.message, contains('tengah'));
    });

    test('face tilted returns tilted status', () {
      final tiltedFace = Face(
        boundingBox: const Rect.fromLTWH(210, 420, 300, 360),
        landmarks: const {},
        contours: const {},
        headEulerAngleY: 25.0, // > 18 deg
      );

      final feedback = guide.evaluate(
        faces: [tiltedFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
      );

      expect(feedback.status, equals(FaceAlignmentStatus.tilted));
      expect(feedback.message, contains('lurus'));
    });

    test('well positioned and stable face advances progress to readyToCapture in auto mode', () async {
      // Face centered at 0.5, 0.45:
      // width = 360 / 720 = 0.50
      // height = 450 / 1280 = 0.35
      // center.dx = 360, center.dy = 576 (576/1280 = 0.45)
      final goodFace = Face(
        boundingBox: const Rect.fromLTWH(180, 351, 360, 450),
        landmarks: const {},
        contours: const {},
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );

      // Frame 1
      final f1 = guide.evaluate(
        faces: [goodFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
        isAutomaticMode: true,
      );
      expect(f1.isRelatable, isTrue);

      // Frame 2 (after small delay)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final f2 = guide.evaluate(
        faces: [goodFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
        isAutomaticMode: true,
      );
      expect(f2.isRelatable, isTrue);
      expect(f2.stabilityProgress, greaterThan(0.0));

      // Repeated stable frames exceeding requiredStableMs (500ms)
      for (int i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        guide.evaluate(
          faces: [goodFace],
          imageSize: const Size(720, 1280),
          rotation: InputImageRotation.rotation0deg,
          isAutomaticMode: true,
        );
      }

      final fFinal = guide.evaluate(
        faces: [goodFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
        isAutomaticMode: true,
      );

      expect(fFinal.status, equals(FaceAlignmentStatus.readyToCapture));
      expect(fFinal.isReadyToCapture, isTrue);
      expect(fFinal.stabilityProgress, equals(1.0));
    });

    test('manual mode does not trigger isReadyToCapture even when stable', () async {
      final goodFace = Face(
        boundingBox: const Rect.fromLTWH(180, 351, 360, 450),
        landmarks: const {},
        contours: const {},
        headEulerAngleY: 0.0,
        headEulerAngleZ: 0.0,
      );

      for (int i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        guide.evaluate(
          faces: [goodFace],
          imageSize: const Size(720, 1280),
          rotation: InputImageRotation.rotation0deg,
          isAutomaticMode: false,
        );
      }

      final fFinal = guide.evaluate(
        faces: [goodFace],
        imageSize: const Size(720, 1280),
        rotation: InputImageRotation.rotation0deg,
        isAutomaticMode: false,
      );

      expect(fFinal.isRelatable, isTrue);
      expect(fFinal.isReadyToCapture, isFalse, reason: 'Manual mode should never auto-capture');
      expect(fFinal.message, contains('dipotret'));
    });
  });
}
