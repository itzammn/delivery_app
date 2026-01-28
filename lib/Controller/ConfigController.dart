import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

/// ConfigController - Manages app configuration from login API
/// Handles ringtone playback for new orders (like Uber/Rapido)
class ConfigController extends GetxController {
  // Config values
  RxInt driverLocationUpdate = 55.obs; // Location update interval in seconds
  RxInt orderCancelSeconds = 34.obs; // Order auto-cancel time in seconds
  RxString ringtoneUrl = "".obs; // Ringtone URL for new orders

  // Audio player for ringtone
  final AudioPlayer _audioPlayer = AudioPlayer();
  RxBool isRingtonePlaying = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  /// Load config from SharedPreferences
  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();

    driverLocationUpdate.value = prefs.getInt("driverLocationUpdate") ?? 55;
    orderCancelSeconds.value = prefs.getInt("orderCancelSeconds") ?? 34;
    ringtoneUrl.value = prefs.getString("ringtoneUrl") ?? "";

    print("📱 Config Loaded:");
    print("   ├── driverLocationUpdate: ${driverLocationUpdate.value}s");
    print("   ├── orderCancelSeconds: ${orderCancelSeconds.value}s");
    print("   └── ringtoneUrl: ${ringtoneUrl.value}");
  }

  /// Save config to SharedPreferences
  Future<void> saveConfig({
    required int locationUpdate,
    required int cancelSeconds,
    required String ringtone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("driverLocationUpdate", locationUpdate);
    await prefs.setInt("orderCancelSeconds", cancelSeconds);
    await prefs.setString("ringtoneUrl", ringtone);

    driverLocationUpdate.value = locationUpdate;
    orderCancelSeconds.value = cancelSeconds;
    ringtoneUrl.value = ringtone;

    print("✅ Config Saved:");
    print("   ├── driverLocationUpdate: ${locationUpdate}s");
    print("   ├── orderCancelSeconds: ${cancelSeconds}s");
    print("   └── ringtoneUrl: $ringtone");
  }

  /// Play ringtone when new order arrives (like Uber/Rapido)
  Future<void> playOrderRingtone() async {
    if (ringtoneUrl.value.isEmpty) {
      print("⚠️ Ringtone URL is empty, skipping playback");
      return;
    }

    try {
      print("🔔 Playing order ringtone...");
      isRingtonePlaying.value = true;

      // Set the audio source
      await _audioPlayer.setUrl(ringtoneUrl.value);

      // Set to loop (keeps playing until stopped)
      await _audioPlayer.setLoopMode(LoopMode.one);

      // Play the ringtone
      await _audioPlayer.play();

      print("🎵 Ringtone started: ${ringtoneUrl.value}");
    } catch (e) {
      print("❌ Error playing ringtone: $e");
      isRingtonePlaying.value = false;
    }
  }

  /// Stop ringtone (call when order is accepted/declined)
  Future<void> stopOrderRingtone() async {
    try {
      await _audioPlayer.stop();
      isRingtonePlaying.value = false;
      print("🔕 Ringtone stopped");
    } catch (e) {
      print("❌ Error stopping ringtone: $e");
    }
  }

  /// Play ringtone once (for search result)
  Future<void> playSearchRingtone() async {
    if (ringtoneUrl.value.isEmpty) {
      print("⚠️ Ringtone URL is empty, skipping playback");
      return;
    }

    try {
      print("🔔 Playing search ringtone (once)...");
      isRingtonePlaying.value = true;

      // Set the audio source
      await _audioPlayer.setUrl(ringtoneUrl.value);

      // Play once (no loop)
      await _audioPlayer.setLoopMode(LoopMode.off);

      // Play the ringtone
      await _audioPlayer.play();

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          isRingtonePlaying.value = false;
        }
      });

      print("🎵 Search ringtone played");
    } catch (e) {
      print("❌ Error playing search ringtone: $e");
      isRingtonePlaying.value = false;
    }
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
