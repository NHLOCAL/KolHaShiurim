#pragma comment(lib, "windowsapp")

#include "include/just_audio_windows/just_audio_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <map>
#include <memory>
#include <sstream>

#include "player.hpp"

using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

// static std::unordered_map<std::string, AudioPlayer> players;
std::vector<std::unique_ptr<AudioPlayer>> players_;

class PlatformThreadTaskRunner {
 public:
  PlatformThreadTaskRunner()
      : platform_thread_id_(GetCurrentThreadId()),
        dispatch_message_(RegisterWindowMessage(
            L"JUST_AUDIO_WINDOWS_PLATFORM_THREAD_DISPATCH")) {
    // Create a message-only window on the platform thread. Posting tasks to
    // this window avoids relying on Flutter's top-level WndProc delegation and
    // reduces reentrancy risk (sending platform channel messages from inside
    // Flutter's own top-level window handler).
    const HINSTANCE instance = GetModuleHandle(nullptr);
    const wchar_t* const kClassName = L"JUST_AUDIO_WINDOWS_TASK_WINDOW";

    WNDCLASS window_class{};
    window_class.lpfnWndProc = PlatformThreadTaskRunner::WndProc;
    window_class.hInstance = instance;
    window_class.lpszClassName = kClassName;
    // Ignore failure if already registered.
    RegisterClass(&window_class);

    hwnd_ = CreateWindowEx(0, kClassName, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                           nullptr, instance, this);
    if (!hwnd_ || dispatch_message_ == 0) {
      std::cerr << "[just_audio_windows] Failed to initialize platform task "
                   "runner window."
                << std::endl;
    }
  }

  ~PlatformThreadTaskRunner() {
    if (hwnd_ && IsWindow(hwnd_)) {
      DestroyWindow(hwnd_);
    }
  }

  void Run(std::function<void()> task) {
    if (!task) {
      return;
    }
    // If already on the platform thread, run immediately.
    if (GetCurrentThreadId() == platform_thread_id_) {
      task();
      return;
    }
    if (!hwnd_ || !IsWindow(hwnd_) || dispatch_message_ == 0) {
      std::cerr << "[just_audio_windows] Dropping platform task (runner not "
                   "initialized)."
                << std::endl;
      return;
    }
    auto* heap_task = new std::function<void()>(std::move(task));
    if (!PostMessage(hwnd_, dispatch_message_, 0,
                     reinterpret_cast<LPARAM>(heap_task))) {
      delete heap_task;
    }
  }

 private:
  static LRESULT CALLBACK WndProc(HWND const hwnd,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept {
    if (message == WM_NCCREATE) {
      auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));
    }

    auto* self = reinterpret_cast<PlatformThreadTaskRunner*>(
        GetWindowLongPtr(hwnd, GWLP_USERDATA));
    if (self && message == self->dispatch_message_) {
      auto* task = reinterpret_cast<std::function<void()>*>(lparam);
      if (task) {
        (*task)();
        delete task;
      }
      return 0;
    }
    return DefWindowProc(hwnd, message, wparam, lparam);
  }

  DWORD platform_thread_id_ = 0;
  UINT dispatch_message_ = 0;
  HWND hwnd_ = nullptr;
};

class JustAudioWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  explicit JustAudioWindowsPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~JustAudioWindowsPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result,
      flutter::BinaryMessenger* messenger);
  // Loops through cameras and returns camera
  // with matching camera_id or nullptr.
  AudioPlayer* GetPlayerByPlayerId(std::string id);

  // Disposes camera by camera id.
  void DisposePlayerByPlayerId(std::string id);

  std::shared_ptr<PlatformThreadTaskRunner> platform_task_runner_;
};

// static
void JustAudioWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.ryanheise.just_audio.methods",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<JustAudioWindowsPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get(), messenger_pointer = registrar->messenger()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result), std::move(messenger_pointer));
      });

  registrar->AddPlugin(std::move(plugin));
}

JustAudioWindowsPlugin::JustAudioWindowsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : platform_task_runner_(std::make_shared<PlatformThreadTaskRunner>()) {}

JustAudioWindowsPlugin::~JustAudioWindowsPlugin() {}

void JustAudioWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result,
    flutter::BinaryMessenger* messenger) {
  const auto* args =std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
    if (method_call.method_name().compare("init") == 0) {
      const auto* id = std::get_if<std::string>(ValueOrNull(*args, "id"));
      if (!id) {
        return result->Error("argument_error", "id argument missing");
      }
      // Ensure all platform channel messages (EventSink::Success/Error) are
      // sent from the platform thread to avoid Flutter engine crashes.
      auto runner = platform_task_runner_;
      auto player = std::make_unique<AudioPlayer>(
          *id, messenger, [runner](std::function<void()> task) {
            if (runner) {
              runner->Run(std::move(task));
            } else if (task) {
              task();
            }
          });
      players_.push_back(std::move(player));
      result->Success();
    } else if (method_call.method_name().compare("disposePlayer") == 0) {
      const auto* id = std::get_if<std::string>(ValueOrNull(*args, "id"));
      if (!id) {
        return result->Error("argument_error", "id argument missing");
      }
      DisposePlayerByPlayerId(*id);
      result->Success(flutter::EncodableMap());
    } else if (method_call.method_name().compare("disposeAllPlayers") == 0) {
      players_.clear();
      result->Success(flutter::EncodableMap());
    } else {
      result->NotImplemented();
    }
  } else {
    result->NotImplemented();
  }
}

AudioPlayer* JustAudioWindowsPlugin::GetPlayerByPlayerId(std::string id) {
  for (auto it = begin(players_); it != end(players_); ++it) {
    if ((*it)->HasPlayerId(id)) {
      return it->get();
    }
  }
  return nullptr;
}

void JustAudioWindowsPlugin::DisposePlayerByPlayerId(std::string id) {
  for (auto it = begin(players_); it != end(players_); ++it) {
    if ((*it)->HasPlayerId(id)) {
      players_.erase(it);
      return;
    }
  }
}

}  // namespace

void JustAudioWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  JustAudioWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
