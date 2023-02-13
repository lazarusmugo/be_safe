import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// location: ^4.3.0
import 'package:geolocator/geolocator.dart';

class MapsView extends StatefulWidget {
  MapsView({required Key key}) : super(key: key);

  @override
  _MapsViewState createState() => _MapsViewState();
}

class _MapsViewState extends State<MapsView> {
  late GoogleMapController mapController;
  var marker = const Marker(
    markerId: MarkerId("1"),
    position: LatLng(45.521563, -122.677433),
    infoWindow: InfoWindow(title: "Location"),
  );

  var currentLocation = LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 11.0,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 400,
        width: double.infinity,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          markers: Set.of([marker]),
          initialCameraPosition: CameraPosition(
            target: currentLocation,
            zoom: 11.0,
          ),
        ),
      ),
    );
  }
}
