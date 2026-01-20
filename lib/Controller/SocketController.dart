import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zamboree/auth/api_helper.dart';

class SocketController extends GetxController {
  IO.Socket? socket;

  RxBool isConnected = false.obs;
  RxBool isAccepting = false.obs;

  RxMap<String, dynamic> lastReceivedOrder = <String, dynamic>{}.obs;

  static const String SOCKET_URL = "https://dev-api.gamsgroup.in";

  @override
  void onInit() {
    super.onInit();
    print("🟡 SocketController initialized");
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
    });

    /// ❌ DISCONNECT
    socket!.onDisconnect((_) {
      print("❌ SOCKET DISCONNECTED");
      isConnected.value = false;
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
      print("🔥 NEW ORDER RECEIVED");
      print("📦 ORDER DATA: $data");

      if (data is Map) {
        lastReceivedOrder.value = Map<String, dynamic>.from(data);
        print("✅ Order saved in controller");
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
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Failed",
          res["message"] ?? "Order accept failed",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print("❌ Accept Order Error: $e");
      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isAccepting.value = false;
    }
  }

  @override
  void onClose() {
    print("🧹 SocketController disposed");
    socket?.disconnect();
    socket?.dispose();
    super.onClose();
  }
}
