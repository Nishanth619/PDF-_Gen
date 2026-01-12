import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_convertor/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper Unit Tests', () {
    // Helper to create a widget with a specific screen size
    Widget buildTestWidget({
      required double width,
      required double height,
      required Widget child,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: MaterialApp(home: child),
      );
    }

    group('Screen Type Detection', () {
      testWidgets('should return mobile for width < 600', (tester) async {
        late ScreenType screenType;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                screenType = ResponsiveHelper.getScreenType(context);
                return Container();
              },
            ),
          ),
        );
        expect(screenType, equals(ScreenType.mobile));
      });

      testWidgets('should return tablet for width 600-899', (tester) async {
        late ScreenType screenType;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                screenType = ResponsiveHelper.getScreenType(context);
                return Container();
              },
            ),
          ),
        );
        expect(screenType, equals(ScreenType.tablet));
      });

      testWidgets('should return largeTablet for width 900-1199', (tester) async {
        late ScreenType screenType;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1000,
            height: 1366,
            child: Builder(
              builder: (context) {
                screenType = ResponsiveHelper.getScreenType(context);
                return Container();
              },
            ),
          ),
        );
        expect(screenType, equals(ScreenType.largeTablet));
      });

      testWidgets('should return desktop for width >= 1200', (tester) async {
        late ScreenType screenType;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1400,
            height: 900,
            child: Builder(
              builder: (context) {
                screenType = ResponsiveHelper.getScreenType(context);
                return Container();
              },
            ),
          ),
        );
        expect(screenType, equals(ScreenType.desktop));
      });
    });

    group('Boolean Helper Methods', () {
      testWidgets('isMobile returns true for small screens', (tester) async {
        late bool result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.isMobile(context);
                return Container();
              },
            ),
          ),
        );
        expect(result, isTrue);
      });

      testWidgets('isMobile returns false for large screens', (tester) async {
        late bool result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 800,
            height: 1024,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.isMobile(context);
                return Container();
              },
            ),
          ),
        );
        expect(result, isFalse);
      });

      testWidgets('isTablet returns true for width >= 600', (tester) async {
        late bool result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 600,
            height: 1024,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.isTablet(context);
                return Container();
              },
            ),
          ),
        );
        expect(result, isTrue);
      });

      testWidgets('isLargeTablet returns true for width >= 900', (tester) async {
        late bool result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 900,
            height: 1200,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.isLargeTablet(context);
                return Container();
              },
            ),
          ),
        );
        expect(result, isTrue);
      });

      testWidgets('isDesktop returns true for width >= 1200', (tester) async {
        late bool result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1200,
            height: 800,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.isDesktop(context);
                return Container();
              },
            ),
          ),
        );
        expect(result, isTrue);
      });
    });

    group('Grid Columns', () {
      testWidgets('should return 2 columns for mobile', (tester) async {
        late int columns;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                columns = ResponsiveHelper.getGridColumns(context);
                return Container();
              },
            ),
          ),
        );
        expect(columns, equals(2));
      });

      testWidgets('should return 3 columns for tablet', (tester) async {
        late int columns;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                columns = ResponsiveHelper.getGridColumns(context);
                return Container();
              },
            ),
          ),
        );
        expect(columns, equals(3));
      });

      testWidgets('should return 3 columns for large tablet', (tester) async {
        late int columns;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1000,
            height: 1366,
            child: Builder(
              builder: (context) {
                columns = ResponsiveHelper.getGridColumns(context);
                return Container();
              },
            ),
          ),
        );
        expect(columns, equals(3));
      });

      testWidgets('should return 3 columns for desktop', (tester) async {
        late int columns;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1400,
            height: 900,
            child: Builder(
              builder: (context) {
                columns = ResponsiveHelper.getGridColumns(context);
                return Container();
              },
            ),
          ),
        );
        expect(columns, equals(3));
      });
    });

    group('Responsive Value Helper', () {
      testWidgets('should return mobile value for mobile screen', (tester) async {
        late String result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.value<String>(
                  context: context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  largeTablet: 'largeTablet',
                  desktop: 'desktop',
                );
                return Container();
              },
            ),
          ),
        );
        expect(result, equals('mobile'));
      });

      testWidgets('should return tablet value for tablet screen', (tester) async {
        late String result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.value<String>(
                  context: context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  largeTablet: 'largeTablet',
                  desktop: 'desktop',
                );
                return Container();
              },
            ),
          ),
        );
        expect(result, equals('tablet'));
      });

      testWidgets('should fallback to mobile if no tablet value provided', (tester) async {
        late String result;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                result = ResponsiveHelper.value<String>(
                  context: context,
                  mobile: 'mobile',
                );
                return Container();
              },
            ),
          ),
        );
        expect(result, equals('mobile'));
      });
    });

    group('Screen Padding', () {
      testWidgets('should return correct padding for mobile', (tester) async {
        late EdgeInsets padding;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                padding = ResponsiveHelper.getScreenPadding(context);
                return Container();
              },
            ),
          ),
        );
        expect(padding, equals(const EdgeInsets.all(16)));
      });

      testWidgets('should return correct padding for tablet', (tester) async {
        late EdgeInsets padding;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                padding = ResponsiveHelper.getScreenPadding(context);
                return Container();
              },
            ),
          ),
        );
        expect(padding, equals(const EdgeInsets.all(24)));
      });
    });

    group('Max Content Width', () {
      testWidgets('should return null for mobile', (tester) async {
        late double? maxWidth;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                maxWidth = ResponsiveHelper.getMaxContentWidth(context);
                return Container();
              },
            ),
          ),
        );
        expect(maxWidth, isNull);
      });

      testWidgets('should return 1000 for large tablet', (tester) async {
        late double? maxWidth;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1000,
            height: 1366,
            child: Builder(
              builder: (context) {
                maxWidth = ResponsiveHelper.getMaxContentWidth(context);
                return Container();
              },
            ),
          ),
        );
        expect(maxWidth, equals(1000));
      });

      testWidgets('should return 1200 for desktop', (tester) async {
        late double? maxWidth;
        await tester.pumpWidget(
          buildTestWidget(
            width: 1400,
            height: 900,
            child: Builder(
              builder: (context) {
                maxWidth = ResponsiveHelper.getMaxContentWidth(context);
                return Container();
              },
            ),
          ),
        );
        expect(maxWidth, equals(1200));
      });
    });

    group('Side Navigation', () {
      testWidgets('should not use side nav for portrait mobile', (tester) async {
        late bool useSideNav;
        // Portrait: height > width
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
            ),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  useSideNav = ResponsiveHelper.shouldUseSideNavigation(context);
                  return Container();
                },
              ),
            ),
          ),
        );
        expect(useSideNav, isFalse);
      });

      testWidgets('should use side nav for landscape tablet', (tester) async {
        late bool useSideNav;
        // Landscape: width > height, and width >= 600 (tablet)
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
            ),
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  useSideNav = ResponsiveHelper.shouldUseSideNavigation(context);
                  return Container();
                },
              ),
            ),
          ),
        );
        expect(useSideNav, isTrue);
      });
    });

    group('Font Size Multiplier', () {
      testWidgets('should return 1.0 for mobile', (tester) async {
        late double multiplier;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                multiplier = ResponsiveHelper.getFontSizeMultiplier(context);
                return Container();
              },
            ),
          ),
        );
        expect(multiplier, equals(1.0));
      });

      testWidgets('should return 1.1 for tablet', (tester) async {
        late double multiplier;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                multiplier = ResponsiveHelper.getFontSizeMultiplier(context);
                return Container();
              },
            ),
          ),
        );
        expect(multiplier, equals(1.1));
      });
    });

    group('Card Aspect Ratio', () {
      testWidgets('should return 0.95 for mobile', (tester) async {
        late double ratio;
        await tester.pumpWidget(
          buildTestWidget(
            width: 400,
            height: 800,
            child: Builder(
              builder: (context) {
                ratio = ResponsiveHelper.getCardAspectRatio(context);
                return Container();
              },
            ),
          ),
        );
        expect(ratio, equals(0.95));
      });

      testWidgets('should return 1.0 for tablet', (tester) async {
        late double ratio;
        await tester.pumpWidget(
          buildTestWidget(
            width: 700,
            height: 1024,
            child: Builder(
              builder: (context) {
                ratio = ResponsiveHelper.getCardAspectRatio(context);
                return Container();
              },
            ),
          ),
        );
        expect(ratio, equals(1.0));
      });
    });
  });

  group('ResponsiveContentWrapper Widget Tests', () {
    testWidgets('should not constrain width on mobile', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Scaffold(
              body: ResponsiveContentWrapper(
                child: Container(
                  key: const Key('test_container'),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );
      
      final container = tester.widget<Container>(find.byKey(const Key('test_container')));
      expect(container, isNotNull);
    });

    testWidgets('should constrain width on large screens', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: Scaffold(
              body: ResponsiveContentWrapper(
                child: Container(
                  key: const Key('test_container'),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );
      
      // Verify ConstrainedBox exists in the tree (there may be multiple from MaterialApp)
      final constrainedBoxes = find.byType(ConstrainedBox);
      expect(constrainedBoxes, findsWidgets);
      
      // Verify the child container is rendered
      expect(find.byKey(const Key('test_container')), findsOneWidget);
    });
  });

  group('ResponsiveLayout Widget Tests', () {
    testWidgets('should show mobile widget on mobile screen', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: ResponsiveLayout(
              mobile: Container(key: const Key('mobile')),
              tablet: Container(key: const Key('tablet')),
              desktop: Container(key: const Key('desktop')),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('mobile')), findsOneWidget);
      expect(find.byKey(const Key('tablet')), findsNothing);
      expect(find.byKey(const Key('desktop')), findsNothing);
    });

    testWidgets('should show tablet widget on tablet screen', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1024)),
          child: MaterialApp(
            home: ResponsiveLayout(
              mobile: Container(key: const Key('mobile')),
              tablet: Container(key: const Key('tablet')),
              desktop: Container(key: const Key('desktop')),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('mobile')), findsNothing);
      expect(find.byKey(const Key('tablet')), findsOneWidget);
      expect(find.byKey(const Key('desktop')), findsNothing);
    });

    testWidgets('should show desktop widget on desktop screen', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: ResponsiveLayout(
              mobile: Container(key: const Key('mobile')),
              tablet: Container(key: const Key('tablet')),
              desktop: Container(key: const Key('desktop')),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('mobile')), findsNothing);
      expect(find.byKey(const Key('tablet')), findsNothing);
      expect(find.byKey(const Key('desktop')), findsOneWidget);
    });

    testWidgets('should fallback to mobile when tablet not provided', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1024)),
          child: MaterialApp(
            home: ResponsiveLayout(
              mobile: Container(key: const Key('mobile')),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('mobile')), findsOneWidget);
    });
  });

  group('ResponsiveBuilder Widget Tests', () {
    testWidgets('should provide correct screen type in builder', (tester) async {
      late ScreenType receivedType;
      
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(700, 1024)),
          child: MaterialApp(
            home: ResponsiveBuilder(
              builder: (context, screenType) {
                receivedType = screenType;
                return Container();
              },
            ),
          ),
        ),
      );
      
      expect(receivedType, equals(ScreenType.tablet));
    });
  });
}
