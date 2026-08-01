import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:zxing2/qrcode.dart';

import '../../common.dart';
import '../../models/platform_model.dart';
import '../hyperos_theme.dart';
import '../widgets/dialog.dart';
import '../widgets/miuix_widgets.dart';

class ScanPage extends StatefulWidget {
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  StreamSubscription? scanSubscription;

  @override
  void reassemble() {
    super.reassemble();
    if (isAndroid && controller != null) {
      controller!.pauseCamera();
    } else if (controller != null) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Scan QR')),
        actions: [
          _buildImagePickerButton(),
          _buildFlashToggleButton(),
          _buildCameraSwitchButton(),
        ],
      ),
      body: _buildQrView(context),
    );
  }

  Widget _buildQrView(BuildContext context) {
    final media = MediaQuery.of(context);
    final scanArea = media.size.width < 400 || media.size.height < 500
        ? 190.0
        : 286.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: HyperosTheme.accent,
            borderRadius: 24,
            borderLength: 34,
            borderWidth: 6,
            cutOutSize: scanArea,
            overlayColor: Colors.black.withOpacity(0.62),
          ),
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: media.padding.bottom + 20,
          child: MiuiSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const MiuiIconContainer(
                  child: Icon(Icons.qr_code_scanner_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    translate('Align QR code within frame'),
                    style: TextStyle(
                      color: HyperosTheme.text(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    scanSubscription = controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        showServerSettingFromQr(scanData.code!);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      showToast(translate('Camera permission denied'));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      try {
        var image = img.decodeImage(await File(file.path).readAsBytes())!;
        LuminanceSource source = RGBLuminanceSource(
          image.width,
          image.height,
          image.getBytes(order: img.ChannelOrder.abgr).buffer.asInt32List(),
        );
        var bitmap = BinaryBitmap(HybridBinarizer(source));

        var reader = QRCodeReader();
        var result = reader.decode(bitmap);
        if (result.text.startsWith(bind.mainUriPrefixSync())) {
          handleUriLink(uriString: result.text);
        } else {
          showServerSettingFromQr(result.text);
        }
      } catch (e) {
        showToast(translate('No QR code found'));
      }
    }
  }

  Widget _buildImagePickerButton() {
    return IconButton(
      tooltip: translate('Choose from gallery'),
      icon: const Icon(Icons.photo_library_rounded),
      onPressed: _pickImage,
    );
  }

  Widget _buildFlashToggleButton() {
    return IconButton(
      tooltip: translate('Toggle flash'),
      icon: const Icon(Icons.flash_on_rounded),
      onPressed: () async {
        await controller?.toggleFlash();
      },
    );
  }

  Widget _buildCameraSwitchButton() {
    return IconButton(
      tooltip: translate('Switch camera'),
      icon: const Icon(Icons.cameraswitch_rounded),
      onPressed: () async {
        await controller?.flipCamera();
      },
    );
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void showServerSettingFromQr(String data) async {
    closeConnection();
    await controller?.pauseCamera();
    if (!data.startsWith('config=')) {
      showToast(translate('Invalid QR code'));
      return;
    }
    try {
      final sc = ServerConfig.decode(data.substring(7));
      Timer(Duration(milliseconds: 60), () {
        showServerSettingsWithValue(sc, gFFI.dialogManager, null);
      });
    } catch (e) {
      showToast(translate('Invalid QR code'));
    }
  }
}
