import 'package:flutter/material.dart';

final String appName = 'ACF Chex';

const double widePhoneWidth = 450;
const double maxTextFieldWidth = 320;

const double appCardElevation = 6;

const EdgeInsets insets8 = EdgeInsets.all(8);
const Padding padding4 = Padding(padding: EdgeInsetsGeometry.all(4));
const Padding padding8 = Padding(padding: EdgeInsetsGeometry.all(8));
const Padding padding16 = Padding(padding: EdgeInsetsGeometry.all(16));
const Padding padding32 = Padding(padding: EdgeInsetsGeometry.all(32));

Padding pad8(Widget child) {
  return Padding(padding: EdgeInsetsGeometry.all(8), child: child);
}

Text largeTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleLarge);

Text mediumTitleText(
  BuildContext context,
  String text, [
  TextAlign textAlign = TextAlign.start,
]) => Text(
  text,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
  ),
  textAlign: textAlign,
);

Text smallTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleSmall);

Scaffold buildScaffold({
  required BuildContext context,
  required String title,
  required Widget child,
  bool makeScrollable = true,
}) {
  return Scaffold(
    appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
    body: PopScope( // For popping persistant snack bars
      canPop: true, // on navigation from the page that displayed them
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }
      },
      child: SafeArea(
        child: pad8(makeScrollable ? buildScrollable(child) : child),
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

Widget wrapList(BuildContext context, Widget child) {
  return center(Container(padding: const EdgeInsets.all(16.0), child: child));
}

BoxDecoration buildBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(32),
  );
}

Widget buildScrollable(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(child: child);
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

Center center(Widget child) {
  return Center(child: child);
}

Widget buildSectionHeader(BuildContext context, String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.only(bottom: 8.0),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

TextFormField buildTextFormField({
  required BuildContext context,
  TextEditingController? controller,
  bool? autoFocus,
  Icon? icon,
  String? Function(String?)? validator,
  bool enabled = true,
}) {
  return TextFormField(
    enabled: enabled,
    controller: controller,
    autofocus: autoFocus ?? false,
    decoration: InputDecoration(
      prefixIcon: icon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      errorMaxLines: 8,
    ),
    validator: validator,
  );
}

Widget cancelButton() {
  return FilledButton(
    child: const Text("Cancel"),
    onPressed: () => unNavigate(),
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
