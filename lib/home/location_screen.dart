// ignore_for_file: deprecated_member_use

import 'package:juodylive/app/setup.dart';
import 'package:juodylive/helpers/quick_help.dart';
import 'package:juodylive/models/UserModel.dart';
import 'package:juodylive/ui/app_bar.dart';
import 'package:juodylive/ui/rounded_gradient_button.dart';
import 'package:juodylive/ui/text_with_tap.dart';
import 'package:juodylive/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:location/location.dart' as LocationForAll;
import 'package:parse_server_sdk/parse_server_sdk.dart';

// ignore: must_be_immutable
class LocationScreen extends StatefulWidget {
  static const String route = '/location';
  LocationScreen({this.currentUser});
  UserModel? currentUser;

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;

  // ── طلب الإذن وجلب الموقع ────────────────────────────────────────────────
  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);

    final location = LocationForAll.Location();

    // 1. تأكد أن الخدمة مفعّلة
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _showError(
          title: "permissions.location_not_supported".tr(),
          message: "permissions.add_location_manually"
              .tr(namedArgs: {"app_name": Setup.appName}),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // 2. تأكد من الإذن
    LocationForAll.PermissionStatus permission = await location.hasPermission();
    if (permission == LocationForAll.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    if (permission == LocationForAll.PermissionStatus.deniedForever) {
      setState(() => _isLoading = false);
      _permissionDeniedForever();
      return;
    }

    if (permission == LocationForAll.PermissionStatus.denied) {
      setState(() => _isLoading = false);
      _showError(
        title: "permissions.location_access_denied".tr(),
        message: "permissions.location_explain"
            .tr(namedArgs: {"app_name": Setup.appName}),
      );
      return;
    }

    // 3. اجلب الموقع
    try {
      final locationData = await location.getLocation();
      await _saveLocation(locationData);
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoading = false);
      _showError(
        title: "permissions.location_access_denied".tr(),
        message: "permissions.location_explain"
            .tr(namedArgs: {"app_name": Setup.appName}),
      );
    }
  }

  // ── حفظ الموقع في Back4App ───────────────────────────────────────────────
  Future<void> _saveLocation(LocationForAll.LocationData locationData) async {
    if (!mounted) return;
    QuickHelp.showLoadingDialog(context);

    final geoPoint = ParseGeoPoint()
      ..latitude  = locationData.latitude!
      ..longitude = locationData.longitude!;

    widget.currentUser!.setHasGeoPoint = true;
    widget.currentUser!.setGeoPoint    = geoPoint;

    final response = await widget.currentUser!.save();
    QuickHelp.hideLoadingDialog(context);

    if (!mounted) return;

    if (response.success && response.results != null) {
      widget.currentUser = response.results!.first as UserModel;

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        user: widget.currentUser,
        title: "permissions.location_updated".tr(),
        message: "permissions.location_updated_explain".tr(),
        isError: false,
      );

      // ✅ أعِد المستخدم المحدَّث للشاشة السابقة
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) QuickHelp.goBackToPreviousPage(context, result: widget.currentUser);
    } else {
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        user: widget.currentUser,
        title: "permissions.location_updated_null".tr(),
        message: "permissions.location_updated_null_explain".tr(),
        isError: true,
      );
      QuickHelp.goBackToPreviousPage(context);
    }
    setState(() => _isLoading = false);
  }

  void _showError({required String title, required String message}) {
    QuickHelp.showAppNotificationAdvanced(
      title: title,
      message: message,
      context: context,
    );
  }

  void _permissionDeniedForever() {
    QuickHelp.showDialogPermission(
      context: context,
      title: "permissions.location_access_denied".tr(),
      confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
      message: "permissions.location_access_denied_explain"
          .tr(namedArgs: {"app_name": Setup.appName}),
      onPressed: () {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.showAppNotificationAdvanced(
          title: "permissions.enable_location".tr(),
          message: "permissions.location_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          context: context,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) async {},
      child: ToolBar(
        leftButtonIcon: QuickHelp.isIOSPlatform()
            ? Icons.arrow_back_ios
            : Icons.arrow_back,
        onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
        child: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 20),
          // ── أيقونة الموقع ─────────────────────────────────────────────
          Icon(Icons.location_on_outlined, color: kPrimaryColor, size: 180),

          // ── نصوص + زر ────────────────────────────────────────────────
          Column(
            children: [
              TextWithTap(
                "permissions.enable_location".tr(),
                marginTop: 20,
                fontSize: 24,
                marginBottom: 8,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                textAlign: TextAlign.center,
              ),
              TextWithTap(
                "permissions.location_explain"
                    .tr(namedArgs: {"app_name": Setup.appName}),
                textAlign: TextAlign.center,
                fontSize: 14,
                marginBottom: 5,
                marginLeft: 30,
                marginRight: 30,
                color: kPrimacyGrayColor,
              ),
              const SizedBox(height: 40),
              // ✅ زر السماح بالموقع
              _isLoading
                  ? const CircularProgressIndicator()
                  : RoundedGradientButton(
                      height: 50,
                      marginLeft: 30,
                      marginRight: 30,
                      marginBottom: 20,
                      borderRadius: 60,
                      borderRadiusBottomLeft: 15,
                      marginTop: 0,
                      fontSize: 16,
                      colors: [kPrimaryColor, kSecondaryColor],
                      textColor: Colors.white,
                      text: "permissions.allow_location".tr().toUpperCase(),
                      fontWeight: FontWeight.w600,
                      onTap: _determinePosition,
                    ),

              // ✅ رابط "معرفة المزيد"
              TextWithTap(
                "permissions.location_tell_more".tr(),
                textAlign: TextAlign.center,
                fontSize: 13,
                marginBottom: 20,
                marginLeft: 40,
                marginRight: 40,
                color: kPrimacyGrayColor,
                onTap: () {
                  QuickHelp.showDialogPermission(
                    context: context,
                    confirmButtonText:
                        "permissions.allow_location".tr().toUpperCase(),
                    title: "permissions.meet_people".tr(),
                    message: "permissions.meet_people_explain".tr(),
                    onPressed: () async {
                      QuickHelp.hideLoadingDialog(context);
                      _determinePosition();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
