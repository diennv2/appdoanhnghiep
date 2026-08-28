import 'dart:async';

import 'package:attendee/pages/break_time_page.dart';
import 'package:attendee/widgets/custom_consent.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:attendee/widgets/custom_snackbar.dart';


class LocationHelper {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;


  final CustomConsentBox _customAlert = CustomConsentBox();



  Future<Position?> getCurrentPosition(BuildContext context) async {

    bool consent = await _showDisclosureDialog(context);
    if (!consent) return null;

    ///Check location service isEnable or not
    if (!await Geolocator.isLocationServiceEnabled()) {
      Geolocator.openLocationSettings();
      return null;
    }

    ///Check/request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: 'Can’t retrieve location—permission required.',
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Location permanently denied',
          actionLabel: 'Settings',
          onAction: Geolocator.openAppSettings,
        );
      }
      return null;
    }

    //get position
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } on TimeoutException {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Location request timed out. Try again.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Error getting location: $e',
        );
      }
    }
    return null;
  }



// user consent dialog box
  Future<bool> _showDisclosureDialog(BuildContext context) async {
    final completer = Completer<bool>();

    _customAlert.showCustomConsentAlert(
      context: context,
      title: 'Allow Background Location Access',
      label:
      'We need your permission to access location in the background so we can track attendance when you enter or leave the office. Your data is secure and private.',
      onResult: (result) => completer.complete(result),
    );

    return completer.future;
  }











  /// Start continuous tracking.
  void startTracking({
    required void Function(Position) onData,
    void Function(ServiceStatus)? onServiceStatus,
    LocationSettings? customSettings,
  }) {
    final settings = customSettings ??
        const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10,
        );



    /// [onData] is called whenever a new [Position] is available.
    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(onData);

    ///Check if the user has turn off the service status or not
    /// [onServiceStatus] can be used to listen to GPS on/off changes
    if (onServiceStatus != null) {
      _serviceStatusSub =
          Geolocator.getServiceStatusStream().listen(onServiceStatus);
    }
  }



  ///Distance Calculation user and user office location
  static double distanceBetween(
      double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,
      ) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  /// Stop any active position or service‐status subscriptions.
  void stopTracking() {
    _positionSub?.cancel();
    _serviceStatusSub?.cancel();
    _positionSub = null;
    _serviceStatusSub = null;
  }






}
