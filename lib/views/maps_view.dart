import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapsView extends StatefulWidget {
  MapsView({required Key key}) : super(key: key);

  @override
  _MapsViewState createState() => _MapsViewState();
}

class _MapsViewState extends State<MapsView> {
  late GoogleMapController mapController;
  late Marker currentLocationMarker = const Marker(
    markerId: MarkerId("currentLocation"),
    position: LatLng(0, 0),
    infoWindow: InfoWindow(title: "Current Location"),
  );

  /* var marker = const Marker(
    markerId: MarkerId("1"),
    position: LatLng(46.521563, -100.677433),
    infoWindow: InfoWindow(title: "Location"),
  );
*/

  // var currentLocation = const LatLng(45.521563, -122.677433);

  /*void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location services disabled"),
            content: const Text(
                "Please enable location services to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location permissions denied"),
            content: const Text(
                "Please grant location permissions to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    if ( //permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
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

    if (permission == LocationPermission.whileInUse) {
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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 300,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }*/

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location services disabled"),
            content: const Text(
                "Please enable location services to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location permissions denied"),
            content: const Text(
                "Please grant location permissions to use this feature."),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        currentLocationMarker = Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentLocation,
          infoWindow: const InfoWindow(title: "Current Location"),
        );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 300,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            markers: currentLocationMarker != null
                ? Set.of([currentLocationMarker])
                : Set<Marker>(),
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 11.0,
            ),
          ),
        ),
      ),
    );
  }
}
