import 'package:flutter/material.dart';
import 'dart:core';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class GroupMapScreen extends StatefulWidget {
  const GroupMapScreen({Key? key}) : super(key: key);

  @override
  State<GroupMapScreen> createState() => _GroupMapScreenState();
}

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);

  @override
  String toString() {
    return 'Location{latitude: $latitude, longitude: $longitude}';
  }
}

class _GroupMapScreenState extends State<GroupMapScreen> {
  int _shareDuration = 1;
  DateTime _customShareDuration = DateTime.now();
  bool _isLocationOn = false;
  bool _alwaysShareLocation = false;

  Set<Marker> _markers = {};

  // Set a default sharing time
  int _sharingTime = 1;

  // Set a default visibility status
  bool _isVisible = true;

  // Update the sharing time when the user changes it
  void _updateSharingTime(int newTime) {
    setState(() {
      _sharingTime = newTime;
    });
  }

  // Update the visibility status when the user changes it
  void _updateVisibility(bool isVisible) {
    setState(() {
      _isVisible = isVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // You can add any initial configuration for the map controller here
  }

  @override
  Widget build(BuildContext context) {
    // Get the group members' locations
    List<Marker> locations = [
      Marker(
        markerId: const MarkerId('marker1'),
        position: const LatLng(1.2921, 36.8219),
        infoWindow: const InfoWindow(
          title: 'User Name',
          snippet: 'Last seen 5 min ago',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('marker2'),
        position: const LatLng(1.544, 40.8219),
        infoWindow: const InfoWindow(
          title: 'User Name',
          snippet: 'Last seen 10 min ago',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    ];

    _markers = locations.toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Map'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sharing Options:',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Always share my location',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: _alwaysShareLocation,
              onChanged: (value) {
                setState(() {
                  _alwaysShareLocation = value;
                });
              },
            ),
            const Text(
              'Share for:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 hour',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: _shareDuration == 1 ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _shareDuration.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    onChanged: (value) {
                      setState(() {
                        _shareDuration = value.toInt();
                      });
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[300],
                  ),
                ),
                Text(
                  '24 hours',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: _shareDuration == 24 ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Or select a custom duration:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      ).then((selectedTime) {
                        if (selectedTime != null) {
                          final now = DateTime.now();
                          final duration = Duration(
                            hours: selectedTime.hour - now.hour,
                            minutes: selectedTime.minute - now.minute,
                          );
                          setState(() {
                            _customShareDuration = now.add(duration);
                          });
                        }
                      });
                    },
                    child: const Text('Select Time'),
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  _customShareDuration != null
                      ? 'Selected duration: ${_customShareDuration.difference(DateTime.now()).inHours} hours ${_customShareDuration.difference(DateTime.now()).inMinutes % 60} minutes'
                      : 'No duration selected',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                markers: _markers,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
