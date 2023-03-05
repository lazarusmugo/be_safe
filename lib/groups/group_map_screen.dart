import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GroupMapScreen extends StatefulWidget {
  const GroupMapScreen({Key? key}) : super(key: key);

  @override
  State<GroupMapScreen> createState() => _GroupMapScreenState();
}

class _GroupMapScreenState extends State<GroupMapScreen> {
  Set<Marker> _markers = {};

  // Set a default sharing time
  int _sharingTime = 1;

  // Update the sharing time when the user changes it
  void _updateSharingTime(int newTime) {
    setState(() {
      _sharingTime = newTime;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    // You can add any initial configuration for the map controller here
  }

  @override
  Widget build(BuildContext context) {
    // Get the group members' locations
    List<Location> locations = [
      Location(51.5074, -0.1278), // London
      Location(40.7128, -74.0060), // New York
      Location(37.7749, -122.4194), // San Francisco
    ];

    _markers = locations.map((location) {
      return Marker(
        markerId: MarkerId(location.toString()),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: const InfoWindow(
          title: 'User Name', // Replace with the user's name
          snippet: 'Last seen 5 min ago', // Replace with the last seen time
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Map'),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show the settings dialog when the user taps the settings icon
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sharing Settings'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Share location for: $_sharingTime hour(s)'),
                        Slider(
                          value: _sharingTime.toDouble(),
                          min: 1,
                          max: 12,
                          divisions: 11,
                          onChanged: (value) {
                            _updateSharingTime(value.toInt());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);
}
