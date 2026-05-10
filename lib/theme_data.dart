import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final String appName = 'ACF Chex';

const double widePhoneWidth = 450;
const double maxTextFieldWidth = 320;

const EdgeInsets insets8 = EdgeInsets.all(8);
const Padding padding8 = Padding(padding: EdgeInsetsGeometry.all(8));
const Padding padding16 = Padding(padding: EdgeInsetsGeometry.all(16));
const Padding padding32 = Padding(padding: EdgeInsetsGeometry.all(32));

Text largeTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleLarge);

Text mediumTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleMedium);

Text smallTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleSmall);

Scaffold buildScaffold({
  required String title,
  required Widget child,
  bool makeScrollable = true,
}) {
  return Scaffold(
    appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
    body: SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.all(64),
        child: makeScrollable ? buildScrollable(child) : child,
      ),
    ),
  );
}

Scaffold oldBuildScaffold({required String title, required Widget child}) {
  return Scaffold(
    appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
    body: SafeArea(child: child),
  );
}

Widget buildScrollable(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: insets8,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
            minWidth: constraints.maxWidth,
          ),
          child: child,
        ),
      );
    },
  );
}

InputDecoration buildInputDecoration(String hint) {
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: OutlineInputBorder(),
    filled: true,
    labelText: hint,
  );
}

void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    showCloseIcon: true,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

ConstrainedBox constrainToPhoneWidth(Widget child) {
  return ConstrainedBox(
    // To prevent the list from taking up the full width of a wide screen
    constraints: const BoxConstraints(maxWidth: widePhoneWidth),
    child: child,
  );
}

ConstrainedBox constrainTextBoxWidth(Widget child) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
    child: child,
  );
}

extension LoadingExtension on BuildContext {
  Future<T> showLoading<T>(Future<T> future) async {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await future;
    } finally {
      Navigator.pop(this);
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<T?> navigate<T>(Widget screen, {String? tag}) async {
  return await navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => screen,
      settings: RouteSettings(name: tag),
    ),
  );
}

void unNavigate<T>({T? result}) {
  navigatorKey.currentState?.pop<T>(result);
}

void unNavigatePast<T>(String tag, {T? result}) {
  navigatorKey.currentState?.popUntil(ModalRoute.withName(tag));
  unNavigate(result: result);
}

class MeasureUtil {
  static Size measureWidget(
    Widget widget, [
    BoxConstraints constraints = const BoxConstraints(),
  ]) {
    final PipelineOwner pipelineOwner = PipelineOwner();
    final _MeasurementView rootView = pipelineOwner.rootNode = _MeasurementView(
      constraints,
    );
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    final RenderObjectToWidgetElement<RenderBox> element =
        RenderObjectToWidgetAdapter<RenderBox>(
          container: rootView,
          debugShortDescription: '[root]',
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: widget,
          ),
        ).attachToRenderTree(buildOwner);
    try {
      rootView.scheduleInitialLayout();
      pipelineOwner.flushLayout();
      return rootView.size;
    } finally {
      // Clean up.
      element.update(
        RenderObjectToWidgetAdapter<RenderBox>(container: rootView),
      );
      buildOwner.finalizeTree();
    }
  }
}

class _MeasurementView extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  final BoxConstraints boxConstraints;

  _MeasurementView(this.boxConstraints);

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(boxConstraints, parentUsesSize: true);
    size = child!.size;
  }

  @override
  void debugAssertDoesMeetConstraints() => true;
}
