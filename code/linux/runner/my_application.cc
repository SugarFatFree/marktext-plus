#include "my_application.h"
#include <cstring>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // Held so a second launch can raise the existing window and hand its file
  // paths to the running instance instead of starting another process.
  GtkWindow* window;
  FlMethodChannel* files_channel;
  FlMethodChannel* clipboard_channel;
};

// Matches the channel name registered in lib/main.dart.
static constexpr char kFilesChannel[] = "com.marktextplus/files";

// Matches _clipboardChannel in lib/services/clipboard_service.dart.
static constexpr char kClipboardChannel[] = "com.marktextplus/clipboard";

// What the clipboard is asked to hand out, and which target is which.
static constexpr int kTargetHtml = 0;
static constexpr int kTargetText = 1;

// One copied selection, in both of its flavours.
//
// GTK does not take a copy of what it is given: it calls back for the data
// when another program asks for it, which may be long after this returns. So
// the strings have to outlive the call, and are freed by the clear callback.
typedef struct {
  gchar* html;
  gchar* text;
} ClipboardPayload;

static void clipboard_get_cb(GtkClipboard* clipboard,
                             GtkSelectionData* selection,
                             guint info,
                             gpointer user_data) {
  ClipboardPayload* payload = static_cast<ClipboardPayload*>(user_data);
  if (info == kTargetHtml) {
    // The atom is the one the target list was built with, so a receiver that
    // asked for text/html is answered in kind.
    gtk_selection_data_set(selection,
                           gtk_selection_data_get_target(selection), 8,
                           reinterpret_cast<const guchar*>(payload->html),
                           strlen(payload->html));
  } else {
    gtk_selection_data_set_text(selection, payload->text, -1);
  }
}

static void clipboard_clear_cb(GtkClipboard* clipboard, gpointer user_data) {
  ClipboardPayload* payload = static_cast<ClipboardPayload*>(user_data);
  g_free(payload->html);
  g_free(payload->text);
  g_free(payload);
}

// Puts one selection on the clipboard as both HTML and plain text.
//
// Pasting into a word processor then keeps the headings and the bold, while
// pasting into a text editor gets the text — which is what every other
// markdown editor does and what this one did on Windows alone.
static void handle_clipboard_call(FlMethodChannel* channel,
                                  FlMethodCall* method_call,
                                  gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(fl_method_call_get_name(method_call), "copyWithHtml") != 0) {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  FlValue* args = fl_method_call_get_args(method_call);
  FlValue* html_value =
      fl_value_lookup_string(args, "html");
  FlValue* text_value =
      fl_value_lookup_string(args, "text");
  if (html_value == nullptr || text_value == nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(
        fl_value_new_bool(FALSE)));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  ClipboardPayload* payload = g_new0(ClipboardPayload, 1);
  payload->html = g_strdup(fl_value_get_string(html_value));
  payload->text = g_strdup(fl_value_get_string(text_value));

  GtkTargetList* list = gtk_target_list_new(nullptr, 0);
  gtk_target_list_add(list, gdk_atom_intern_static_string("text/html"), 0,
                      kTargetHtml);
  gtk_target_list_add_text_targets(list, kTargetText);
  int n_targets = 0;
  GtkTargetEntry* targets = gtk_target_table_new_from_list(list, &n_targets);

  GtkClipboard* clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  gboolean ok = gtk_clipboard_set_with_data(clipboard, targets, n_targets,
                                            clipboard_get_cb,
                                            clipboard_clear_cb, payload);
  if (ok) {
    gtk_clipboard_set_can_store(clipboard, nullptr, 0);
  } else {
    // Nothing took ownership, so nothing will ever call the clear callback.
    clipboard_clear_cb(clipboard, payload);
  }

  gtk_target_table_free(targets, n_targets);
  gtk_target_list_unref(list);

  response = FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(ok)));
  fl_method_call_respond(method_call, response, nullptr);
}

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  if (self->window != nullptr) {
    gtk_window_present(self->window);
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "MarkText Plus");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "MarkText Plus");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  self->window = window;
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->files_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), kFilesChannel,
      FL_METHOD_CODEC(codec));
  self->clipboard_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kClipboardChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->clipboard_channel, handle_clipboard_call, self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::open.
//
// With G_APPLICATION_HANDLES_OPEN, GApplication forwards a second launch to
// the process that already holds the application ID, so this runs inside the
// running instance.
static void my_application_open(GApplication* application, GFile** files,
                                gint n_files, const gchar* hint) {
  MyApplication* self = MY_APPLICATION(application);

  if (self->window == nullptr) {
    // First launch: the paths are already in dart_entrypoint_arguments, which
    // main.dart reads on startup.
    my_application_activate(application);
    return;
  }

  g_autoptr(FlValue) paths = fl_value_new_list();
  for (gint i = 0; i < n_files; i++) {
    g_autofree gchar* path = g_file_get_path(files[i]);
    if (path != nullptr) {
      fl_value_append_take(paths, fl_value_new_string(path));
    }
  }

  if (self->files_channel != nullptr && fl_value_get_length(paths) > 0) {
    fl_method_channel_invoke_method(self->files_channel, "openFiles", paths,
                                    nullptr, nullptr, nullptr);
  }

  gtk_window_present(self->window);
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  // Hand any existing file arguments to open(), so a second launch reaches the
  // running instance rather than starting a new one.
  g_autoptr(GPtrArray) files = g_ptr_array_new_with_free_func(g_object_unref);
  for (gchar** arg = *arguments + 1; *arg != nullptr; arg++) {
    if (g_file_test(*arg, G_FILE_TEST_EXISTS)) {
      g_ptr_array_add(files, g_file_new_for_commandline_arg(*arg));
    }
  }

  if (files->len > 0) {
    g_application_open(application, reinterpret_cast<GFile**>(files->pdata),
                       files->len, "");
  } else {
    g_application_activate(application);
  }

  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->files_channel);
  g_clear_object(&self->clipboard_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_HANDLES_OPEN, nullptr));
}
