import 'dart:html' as html;

void replaceUrlPath(String path) {
  try {
    html.window.history.replaceState(null, 'MyCloudBook', path);
  } catch (_) {}
}


