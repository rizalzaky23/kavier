import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/kasir/data/models/transaction_model.dart';

class PrinterService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final NumberFormat _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Meminta seluruh izin yang dibutuhkan untuk Bluetooth (Android 12+)
  Future<bool> checkPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  }

  /// Mendapatkan daftar perangkat bluetooth yang sudah di-pair
  Future<List<BluetoothDevice>> getPairedDevices() async {
    bool? isOn = await bluetooth.isOn;
    if (isOn != true) {
      throw Exception('Bluetooth tidak aktif. Nyalakan Bluetooth terlebih dahulu.');
    }
    try {
      final devices = await bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      throw Exception('Gagal membaca daftar perangkat: $e');
    }
  }

  /// Menghubungkan ke perangkat printer (dengan timeout 10 detik)
  Future<void> connect(BluetoothDevice device) async {
    // Pastikan disconnect dulu jika masih terhubung
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
        // Beri jeda agar device siap
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {}

    // Connect dengan timeout 10 detik (printer Eyes kadang butuh waktu)
    await bluetooth.connect(device).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'Koneksi timeout. Pastikan printer Eyes:\n'
          '• Sudah menyala\n'
          '• Sudah di-pair di Pengaturan Bluetooth\n'
          '• Berada dalam jarak dekat',
        );
      },
    );

    // Beri jeda singkat setelah connect agar printer siap menerima data
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Mencetak format Nota (lebar 58mm = ~32 karakter per baris)
  Future<void> printReceipt(TransactionModel transaction, List<dynamic> items) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      throw Exception('Printer belum terhubung');
    }

    try {
      // HEADER
      bluetooth.printNewLine();
      bluetooth.printCustom('Kentunk Caffe and Bar', 2, 1); // size=2, align=center
      bluetooth.printCustom('Jl. Pasar kembang. gang 2', 0, 1);
      bluetooth.printCustom('Kota Yogyakarta', 0, 1);
      bluetooth.printCustom('================================', 0, 1);

      // INFO TRANSAKSI
      DateTime dt = DateTime.tryParse(transaction.createdAt) ?? DateTime.now();
      bluetooth.printLeftRight(
          'No: ${transaction.invoiceNumber}',
          DateFormat('dd/MM/yy HH:mm').format(dt),
          0);
      bluetooth.printCustom('Kasir: Admin', 0, 0);
      bluetooth.printCustom('================================', 0, 1);

      // DAFTAR ITEM
      for (var item in items) {
        String name = item.name.length > 20
            ? item.name.substring(0, 20)
            : item.name;
        bluetooth.printCustom(name, 0, 0);
        String qtyPrice = '${item.quantity} x ${_fmt.format(item.price)}';
        String subtotal = _fmt.format(item.subtotal);
        bluetooth.printLeftRight(qtyPrice, subtotal, 0);
      }
      bluetooth.printCustom('================================', 0, 1);

      // TOTALS
      bluetooth.printLeftRight('Subtotal', _fmt.format(transaction.subtotal), 0);
      if (transaction.discount > 0) {
        bluetooth.printLeftRight('Diskon', '- ${_fmt.format(transaction.discount)}', 0);
      }
      bluetooth.printCustom('--------------------------------', 0, 1);
      bluetooth.printLeftRight('TOTAL', _fmt.format(transaction.total), 1);
      bluetooth.printCustom('--------------------------------', 0, 1);
      bluetooth.printLeftRight('Dibayar', _fmt.format(transaction.paidAmount), 0);
      bluetooth.printLeftRight('Kembalian', _fmt.format(transaction.changeAmount), 0);
      bluetooth.printCustom('================================', 0, 1);

      // FOOTER
      bluetooth.printNewLine();
      bluetooth.printCustom('Terima Kasih!', 1, 1);
      bluetooth.printCustom('Barang yang sudah dibeli', 0, 1);
      bluetooth.printCustom('tidak dapat ditukar/dikembalikan', 0, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      // Cut paper (opsional — tidak semua printer Eyes mendukung)
      try {
        bluetooth.paperCut();
      } catch (_) {}
    } catch (e) {
      throw Exception('Gagal mencetak: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
    } catch (_) {}
  }
}
