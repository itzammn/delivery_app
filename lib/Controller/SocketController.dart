import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zamboree/auth/api_helper.dart';
import 'package:zamboree/Controller/ConfigController.dart';
import 'package:zamboree/Controller/LocationController.dart';

class SocketController extends GetxController {
  IO.Socket? socket;

  RxBool isConnected = false.obs;
  RxBool isAccepting = false.obs;
  RxBool isOnline = false.obs; //  Track business online status

  RxMap<String, dynamic> lastReceivedOrder = <String, dynamic>{}.obs;

  Timer? _locationTimer;

  static const String SOCKET_URL = "https://dev-api.gamsgroup.in";

  @override
  void onInit() {
    super.onInit();
    print("🟡 SocketController initialized");
  }

  /// 🟢 Set Driver Online/Offline status
  void setOnlineStatus(bool online) {
    isOnline.value = online;
    if (!online) {
      // 🧹 Clear everything when going offline
      lastReceivedOrder.clear();
      Get.find<ConfigController>().stopOrderRingtone();
      print("🧹 Offline: Cleared orders and stopped ringtone");
    }
  }

  /// 🔌 CONNECT SOCKET (after going online)
  Future<void> connectSocket() async {
    if (socket != null && socket!.connected) {
      print("⚠️ Socket already connected");
      return;
    }

    print("🔌 Connecting socket to $SOCKET_URL");

    socket = IO.io(
      SOCKET_URL,
      IO.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setTimeout(20000)
          .build(),
    );

    /// ✅ CONNECT
    socket!.onConnect((_) {
      print("✅ SOCKET CONNECTED");
      print("🆔 Socket ID: ${socket!.id}");
      isConnected.value = true;
      joinRoom();
      startLocationUpdates(); // 📍 START UPDATING LOCATION
    });

    /// ❌ DISCONNECT
    socket!.onDisconnect((_) {
      print("❌ SOCKET DISCONNECTED");
      isConnected.value = false;
      stopLocationUpdates(); // 🛑 STOP UPDATING LOCATION
    });

    /// ⚠️ ERROR
    socket!.onConnectError((err) {
      print("🚨 CONNECT ERROR: $err");
    });

    socket!.onError((err) {
      print("🚨 SOCKET ERROR: $err");
    });

    /// 🧪 DEBUG ALL EVENTS
    socket!.onAny((event, data) {
      print("📡 EVENT: $event");
      print("📦 DATA: $data");
    });

    /// 📦 NEW ORDER EVENT
    socket!.on("order:new", (data) {
      // 🚫 Only process if driver is ONLINE
      if (!isOnline.value) {
        print("ℹ️ Order received but driver is OFFLINE. Ignoring.");
        return;
      }

      print("🔥 NEW ORDER RECEIVED");
      print("📦 ORDER DATA: $data");

      if (data is Map) {
        lastReceivedOrder.value = Map<String, dynamic>.from(data);
        print("✅ Order saved in controller");

        // 🔔 PLAY RINGTONE (like Uber/Rapido)
        try {
          final configController = Get.find<ConfigController>();
          configController.playOrderRingtone();
          print("🔔 Order ringtone triggered");
        } catch (e) {
          print("⚠️ Could not play ringtone: $e");
        }
      } else {
        print("❌ Invalid order format");
      }
    });

    socket!.connect();
  }

  /// 🏠 JOIN DELIVERY PARTNER ROOM
  Future<void> joinRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString("delivery_partner_id");

    print("🔍 delivery_partner_id: $partnerId");

    if (partnerId == null || partnerId.isEmpty) {
      print("❌ Partner ID not found");
      return;
    }

    print("🏠 Joining room: $partnerId");
    socket!.emit("join", partnerId);
  }

  /// ✅ ACCEPT ORDER (API + SOCKET)
  Future<void> acceptOrder(String orderId) async {
    if (orderId.isEmpty) {
      print("❌ orderId empty");
      return;
    }

    if (isAccepting.value) return;

    try {
      isAccepting.value = true;

      print("📤 Calling ACCEPT ORDER API → $orderId");

      final res = await ApiHelper.acceptOrder(orderId);

      print("📥 Accept API Response: $res");

      if (res["success"] == true) {
        print("✅ Order accepted successfully");

        // 🔕 STOP RINGTONE
        try {
          Get.find<ConfigController>().stopOrderRingtone();
        } catch (e) {
          print("⚠️ Could not stop ringtone: $e");
        }

        /// (Optional) socket emit if backend expects it
        if (socket != null && socket!.connected) {
          socket!.emit("order:accept", {"orderId": orderId});
          print("📡 order:accept emitted");
        }

        /// Clear UI order
        lastReceivedOrder.clear();

        Get.snackbar(
          "Order Accepted",
          "Order accepted successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Failed",
          res["message"] ?? "Order accept failed",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("❌ Accept Order Error: $e");
      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isAccepting.value = false;
    }
  }

  /// 📍 START PERIODIC LOCATION UPDATES
  void startLocationUpdates() {
    stopLocationUpdates(); // Ensure no duplicate timers

    final configController = Get.find<ConfigController>();
    int interval = configController.driverLocationUpdate.value;
    if (interval <= 0) interval = 55; // Fallback

    print("🚀 Starting location updates every $interval seconds");

    _locationTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      sendLocationUpdate();
    });
  }

  /// 🛑 STOP PERIODIC LOCATION UPDATES
  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print("🛑 Location updates stopped");
  }

  /// 📤 SEND LOCATION TO BACKEND via Socket
  Future<void> sendLocationUpdate() async {
    if (socket == null || !socket!.connected) return;

    final locationController = Get.find<LocationController>();
    double lat = locationController.latitude.value;
    double lng = locationController.longitude.value;

    if (lat == 0.0 || lng == 0.0) {
      print("⚠️ Skipping location update: lat/lng is 0.0");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final partnerId = prefs.getString("delivery_partner_id");

    if (partnerId != null) {
      print("📤 Sending location update: [$lat, $lng]");
      socket!.emit("update-location", {
        "deliveryPartnerId": partnerId,
        "latitude": lat,
        "longitude": lng,
      });
    }
  }

  @override
  void onClose() {
    print("🧹 SocketController disposed");
    stopLocationUpdates();
    socket?.disconnect();
    socket?.dispose();
    super.onClose();
  }
}
