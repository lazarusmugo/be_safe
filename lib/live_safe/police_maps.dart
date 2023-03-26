import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceMapPage extends StatefulWidget {
  @override
  _PoliceMapPageState createState() => _PoliceMapPageState();
}

class _PoliceMapPageState extends State<PoliceMapPage> {
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  late GoogleMapController mapController;
  late Marker currentLocationMarker = const Marker(
    markerId: MarkerId("currentLocation"),
    position: LatLng(0, 0),
    infoWindow: InfoWindow(title: " This is your Current Location"),
  );

  @override
  void initState() {
    super.initState();
    _getEmergencyUsers();

    _polylines.add(const Polyline(
      polylineId: PolylineId('InitialPolyline'),
      points: [],
      color: Colors.blue,
      width: 5,
    ));
  }

  Future<void> _getEmergencyUsers() async {
    final emergencySnapshot = await FirebaseFirestore.instance
        .collection('emergencies')
        .where('emergencyMode', isEqualTo: true)
        .get();

    final userIds = <String>[];
    for (final doc in emergencySnapshot.docs) {
      userIds.add(doc.id);
    }
    print('list of emergency ids is $userIds');

    final groupsSnapshot =
        await FirebaseFirestore.instance.collection('groups').get();

    for (final groupDoc in groupsSnapshot.docs) {
      final groupId = groupDoc.id;
      final groupMembersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('group_members')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      print(
          'Number of documents in groupSnapshot: ${groupMembersSnapshot.docs.length}');
      final markers = <Marker>[];
      try {
        for (final doc in groupMembersSnapshot.docs) {
          final data = doc.data();

          if (data['isVisible'] &&
              data['visibleUntil'].toDate().isAfter(DateTime.now()) != null) {
            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(
                    data['location'].latitude, data['location'].longitude),
                infoWindow: InfoWindow(
                  title: data['username'],
                  snippet: 'Help, im in danger',
                ),
                onTap: () {
                  // handle marker tap here
                  _showUserDetailsDialog(data);
                },
              ),
            );
          }
        }
      } catch (e) {
        print('Error getting mapping details $e');
      }

      setState(() {
        if (mounted) {
          _markers.addAll(markers);
        }
      });
    }
  }

  void _showUserDetailsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(data['username']),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['profilePhotoUrl'] != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(data['profilePhotoUrl']),
                      radius: 40,
                    ),
                  const SizedBox(height: 16),
                  Text(
                      '${data['username']} Has shared their location until: ${data['visibleUntil'].toDate()}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=${data['location'].latitude},${data['location'].longitude}';

                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      throw 'Could not launch $url';
                    }

                    /* // handle tracking the user here
                    Navigator.of(context)
                        .pop(); // dismiss the user details dialog
                    final userLocation = data['location'];

                    Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high);
                    LatLng policeLocation =
                        LatLng(position.latitude, position.longitude);
                    // final policeLocation = await _getCurrentLocation();
                    setState(() {
                      if (mounted) {
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('Police'),
                            position: policeLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen),
                          ),
                        );
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('User'),
                            position: LatLng(
                                userLocation.latitude, userLocation.longitude),
                            infoWindow: InfoWindow(
                              title: data['username'],
                              snippet: 'Help, im in danger',
                            ),
                          ),
                        );
                        _polylines.add(Polyline(
                          polylineId: const PolylineId('UserTrack'),
                          points: [
                            policeLocation,
                            LatLng(
                                userLocation.latitude, userLocation.longitude)
                          ],
                          color: Colors.blue,
                          width: 5,
                        ));
                      }
                    }); */
                  },
                  child: const Text('Track'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
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
            zoom: 5.0,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Map Page'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
        ),
        markers: {
          ..._markers.toSet(),
          if (currentLocationMarker != null) currentLocationMarker,
        },
        onTap: (LatLng latLng) {
          // hide the user details dialog if it is currently shown
          Navigator.of(context).pop();
        },
        polylines: _polylines.toSet(),
      ),
    );
  }
}
